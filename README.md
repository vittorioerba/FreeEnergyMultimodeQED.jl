# FreeEnergyMultimodeQED.jl julia library

A small library to reproduce the results of CITA

The package contains:
- an implementation of the gradient descent used in the paper;
- an interface to the non-positive-definite QP solver of [CPLEX](https://www.ibm.com/analytics/cplex-optimizer) through [JuMP](https://jump.dev/), used in the paper to perform global optimization of the model;
- an interface to the interior point solver of [IPOPT](https://coin-or.github.io/Ipopt/) through [JuMP](https://jump.dev/), not used in the paper, but possibly useful.

A number of helper function implementing the model of the paper are also available.

## Installation

To install the package to your local machine, you can use Julia's package manager [Pkg.jl](https://github.com/JuliaLang/Pkg.jl).
Start a Julia REPL, and run
``` 
    ] add https://github.com/vittorioerba/FreeEnergyMultimodeQED.jl.git
```

## Documentation

The code is documented through docstrings in the code, at least for all exported functions.
A list of exported functions can be found in [src/FreeEnergyMultimodeQED.jl](src/FreeEnergyMultimodeQED.jl).
To see what an exported function does, just use the bulit-in Julia help
```
    ? function_name
```
