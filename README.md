# VirtualPlantLab

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](http://virtualplantlab.com/)
[![CI](https://github.com/VirtualPlantLab/VirtualPlantLab.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/VirtualPlantLab/VirtualPlantLab.jl/actions/workflows/CI.yml)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This is the main package in the [Virtual Plant Lab](http://virtualplantlab.com/) that users
are meant to download and use. It is a meta-package that includes all the other packages
in the VirtualPlantLab organization where the different features are implemented. The user
does not need to be aware of the other packages, except in cases where methods need to be
define for user-defined types (currently that is the case for `PlantGeomTurtle.feed!()`
which is required to generate geometry from user-defined types).

# 1. Instalation

You can install the latest stable version of PlantGraphs.jl with the Julia package manager:

```julia
] add VirtualPlantLab
```

Or the development version directly from here:

```julia
import Pkg
Pkg.add(url="https://github.com/VirtualPlantLab/VirtualPlantLab.jl", rev = "master")
```
or

```julia
] add VirtualPlantLab#master
```

# 2. Usage

To start using VirtualPlantLab.jl, you need to load it first:

```julia
using VirtualPlantLab
```

The entire API of the Virtual Plant Lab will become available after loading.

For people starting, it is recommended to follow the tutorials in the
[documentation](http://virtualplantlab.com/). The entire API is also documented there.

# 3. Additional packages

The following packages are also of interest when building models with the Virtual Plant Lab:

- [PlantSimEngine.jl](https://github.com/VirtualPlantLab/PlantSimEngine.jl)
- [PlantBiophysics.jl](https://github.com/VEZY/PlantBiophysics.jl.git)
- [SkyDomes.jl](https://github.com/VirtualPlantLab/SkyDomes.jl)
- [Ecophys.jl](https://github.com/VirtualPlantLab/Ecophys.jl.git)
