module FreeEnergyMultimodeQED

ENV["CPLEX_STUDIO_BINARIES"] = "/opt/ibm/ILOG/CPLEX_Studio1210/cplex/bin/x86-64_linux"

using Random                     # utils
using LinearAlgebra              # model
using CPLEX, Dates, Ipopt, JuMP  # optimiziers
using DelimitedFiles             # simulations, parsing
using DataFrames, JLD, StatsBase # parsing

export coprimeFractionsGenerator
export gradMagnetizationEntropy, gradModelFreeEnergy, magnetizationEntropy, modelDimension, modelEntropy, modelFreeEnergy, modelInteraction
export modelFindMinimum
export simulateGS, simulateMinima
export analyzeGS, analyzeMinima, checkMinimaFound, getTotalRuns, parseRawData, preprocessRawDataframe

include("utils.jl")             # utility functions
include("model.jl")             # model-related functions
include("optimizers.jl")        # optimizers to find minima of the free energy of the model
include("simulations.jl")       # utlities for simulations
include("parsing.jl")           # utilities for data processing

end
