# Self-induced glassy phase in multimodal cavity quantum electrodynamics

In this repository you can find the julia code for the paper ["Self-induced glassy phase in multimodal cavity quantum electrodynamics"](https://arxiv.org/pdf/2101.03754.pdf).

The package contains:
- an implementation of the constrained gradient descent used in the paper;
- an interface to the non-positive-definite QP solver of [CPLEX](https://www.ibm.com/analytics/cplex-optimizer) through [JuMP](https://jump.dev/), used in the paper to perform global optimization of the model.

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
