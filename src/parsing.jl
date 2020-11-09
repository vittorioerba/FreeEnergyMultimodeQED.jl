"""
    parseRawData(file::String)

Takes as input a csv file whose lines are of the form 
```
    p | q | temperature | optimizer | minimum configuration | starting configuration | timestamp  | timespan of optimization | status
```
and parses it into a DataFrame.
"""
function parseRawData(file::String)
    raw = readdlm(file,'|') 
    raw[:,4] = map( Symbol , raw[:,4])
    raw[:,5] = map( u -> parse.(Float64,split(u[2:end-1],", ")) , raw[:,5])
    raw[:,6] = map( u -> u=="Any[]" ? Vector{Float64}() : parse.(Float64,split(u[2:end-1],", ")) , raw[:,6])
    raw[:,7] = map( string , raw[:,7])
    raw[:,9] = map( string |> u->u=="FEASIBLE_POINT" ? "good" : u , raw[:,9])
    tup = Vector{Tuple}()
    for row in eachrow(raw)
        if row[9] == "FEASIBLE_POINT"
            row[9] = "good"
        end
        push!(tup,Tuple(row))
    end
    data = DataFrame(tup)
    names = [:p, :q, :temperature, :optimizer, :minimum, :starting, :id, :time, :status]
    names!(data,names)
    data
end

"""
    preprocessRawDataframe(db::DataFrame)

Takes as input a raw-data DataFrame generated by ```parseRawData``` and returns a new DataFrame ovtained by:
1)  selecting only gradient-based simulations;
2)  selecting only the successful simulations based on the exit status;
3)  selecting only zero-temperature simulations;
4)  adding a column with the total number of valid simulations;
5)  adding a column with ```minimum``` rounded to the first decimal digit, and flipped such that the first non-null magnetization is positive;
6)  adding a column with the value of the energy of ```minimum``` rounded to the second decimal digit;
7)  adding a column with the value of the entropy of ```minimum``` rounded to the second decimal digit.
"""
function preprocessRawDataframe(db::DataFrame)
    # select gradient
    db = db[ db.optimizer .|> u->occursin("gradient",u |> string ) , :]
    # select good simulations
    db = db[db.status .== "good", :]
    # select zero temperature
    db = db[db.temperature .== 0., :]
    # totalTrials
    tot = nrow(db)
    db.totalTrials = ones(tot)*tot
    # add info on ground state configuration (rounded to 1 decimal, I'm interested in 0,+-1 basically) normalized to factor out the Z2 symmetry
    db.cleanMinimum = map( u -> roundVector(u[:minimum],digits=1) |> flipZ2 , db |> eachrow)
    # and info on free energy of the exact minimum found, rounded to the second decimal
    db.energy = map( u -> roundVector(modelFreeEnergy(u[:minimum],u[:p],u[:q],u[:temperature]),digits=2) , db |> eachrow)
    # and info on entropy of the clean minimum found, rounded to the second decimal
    db.entropy = map( u -> roundVector(modelEntropy(u[:minimum],u[:q]),digits=2) , db |> eachrow)

    return db
end

"""
    analyzeGS(db::DataFrame, file::String)

Takes a preprocessed DataFrame and extracts informations about the ground state (GS).
It saves the GS energy and the list of distinct GSs into a Dictionary with fields ```energy, states```.
It exports the results using the package ```JLD``` into the file specified by ```file```; ```file``` must have extension ```.jld```.
    
"""
function analyzeGS(db::DataFrame, file::String)

    groundStateEnergy = min(db.energy...)
    groundStates = db[db.energy .== groundStateEnergy,:].cleanMinimum |> unique

    save(
         file,
         Dict(
            "energy"     => groundStateEnergy,
            "states"     => groundStates
           )
        )
end

"""
    analyzeMinima(db::DataFrame, file::String)

Takes a preprocessed DataFrame and extracts informations about the local minima of the energy landscape.
It saves  the list of distinct minima, the linear size of their basins of attraction and an estimate of the volume of the basins of attraction into a Dictionary with fields ```states, basinsLinear, basinsVolume```.
It exports the results using the package ```JLD``` into the file specified by ```file```; ```file``` must have extension ```.jld```.


The estimate of the volume of a basin of attraction is given by the number of descents that ends in the corresponding minimum.

The estimate of the linear size of a basin of attraction is given by the distance between all initial conditions and the minimum currently under study.
This given, one can compute the maximum distance for example, or any other useful statistic.
"""
function analyzeMinima(db::DataFrame, file::String)
    
    # add useful columns to db
    db.distance = map( u -> norm(u[1]-u[2]), zip(db.cleanMinimum, db.starting))

    # states 
    tmp = db.cleanMinimum |> countmap
    states = tmp |> keys |> collect

    l = length(states)
    basinNumber = Vector{Int64}(undef,l)
    basinDistances = Vector{Vector{Float64}}(undef,l)
    for (i,s) in enumerate(states)
        basinNumber[i] = tmp[s]
        basinDistances[i] = db.distance[db.cleanMinimum .== [s]]
    end
    save(
         file,
         Dict(
            "states"       => states,
            "basinsLinear" => basinDistances,
            "basinsVolume" => basinNumber
           )
        )
end


"""
    checkMinimaFound(db::DataFrame, file::String)

Takes a preprocessed DataFrame and returns the curve of the number of distinct minima found VS the number of descent runs performed as a ```Matrix``` of size ```numberRuns x 2```, and saves it into a dictionary ith fields ```saturationCurve```.
It exports the results using the package ```JLD``` into the file specified by ```file```; ```file``` must have extension ```.jld```.

Every time it is called, it recomputed this saturation curve using a different random permuation of the rows of ```db```.


"""
function checkMinimaFound(db::DataFrame, file::String)
    # saturation of metastable states vs total trials
    vec = db.cleanMinimum
    distinctMin = Set{Vector{Float64}}()
    history = Matrix{Float64}(undef,length(vec),2)
    perm = randperm(length(vec))
    for i in 1:length(vec)
        if !(vec[perm[i]] in distinctMin)
            push!(distinctMin, vec[perm[i]])
        end
        history[i,:] = [ i,length(distinctMin)]
    end 
    save(
         file,
         Dict(
            "saturationCurve"       => history
           )
        )
end

"""
    whichQP(directory::String)

Assuming that ```directory``` contains only the raw data simulated, with one file per pair (p,q) named, for example, q17_p4.csv, it returns a list of tuples with the simulated values of (q,p).

"""
function whichQP(directory::String)
    res = []
    for file in readdir(directory)
        push!(res, Tuple(split(file[2:end-4],"_p") .|> u->parse(Int64,u) )) 
    end
    return res
end

"""
    getTotalRuns(file::String)

Counts the numer of lines of file.

NOTICE: one could also use the built-in function ```countlines(file)```. It seems that on small files ```countlines``` is faster than the shell command ```wc```, while on a file of ~300000 lines ```wc``` is faster.
In all cases, the difference is not very important, and ```countlines``` allocates lesser memory than ```wc```.
"""
function getTotalRuns(file::String)
    read(pipeline(`wc -l $file`,`cut -d ' ' -f 1 `), String) |> u -> parse(Int,u)
end
