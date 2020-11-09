"""
    simulateGS(p::Int,q::Int,file::String)

Optimizes the model at parameters (p,q) looking for a global minimum using the :cplex optimizer, and appends the result to ```file```.
 
"""
function simulateGS(p::Int,q::Int,file::String)
    open(file, "a") do io
        writedlm(io, [modelFindMinimum(p,q,optimizer=:cplex)], '|')
    end
end

"""
    simulateMinima(p::Int,q::Int,iter::Int,file::String)

Optimizes the model at parameters (p,q) looking for a local minimum using the :gradient optimizer, and appends the result to ```file```.
It iterates the search ```iter``` times starting from random initial conditions. 
"""
function simulateMinima(p::Int,q::Int,iter::Int,file::String)
    result = []
    for i in 1:iter
        push!(result, modelFindMinimum(p,q))
    end
    open(file, "a") do io
        writedlm(io, result, '|')
    end
end


"""
    heatAndCool(p::Int,q::Int,ts::Vector{T};) where T <: Real
    heatAndCool(p::Int,q::Int,ts::Vector{T};eta::Real) where T <: Real

It performs an heating and cooling experiment of the model at parameters (p,q) by iterating through the given temperatures ```ts```, and minimizing locally the free energy using the :gradient optimizer.

Before being used as initial condition for a new minimization, the final condition of the previous minimization is perturbed by adding a noise of strength ```eta``` to avoid memory effects. ```eta``` defaults to ```1e-2```.

The initial condition is given by ```startingCondition```, which defaults to a random initial condition if nothing is specified.

"""
function heatAndCool(p::Int,q::Int,ts::Vector{T};
                     eta::Real=1e-2,
                     startingCondition::Vector{T} = rand(Float64,modelDimension(q)) .|> u -> 2*u-1
                    ) where T <: Real

    # record energies
    result = []
    current = startingCondition

    # change the temperature of the system and minimize it locally
    for t in ts
        current = modelFindMinimum(p,q; optimizer=:gradient,
                            temperature=t,
                            startingCondition=addNoise(current;eta=eta)
                           )[5]
        push!(result,[t,current])
    end

    return result
end


