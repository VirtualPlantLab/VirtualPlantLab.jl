#=
# Ray-traced forest

Alejandro Morales

Centre for Crop Systems Analysis - Wageningen University


In this example we extend the forest growth model to include PAR interception a
radiation use efficiency to compute the daily growth rate.

The following packages are needed:

=#
using VirtualPlantLab, ColorTypes
import GLMakie
using Base.Threads: @threads
using Plots
import Random
using FastGaussQuadrature
using Distributions
using SkyDomes
Random.seed!(123456789)
#=

## Model definition

### Node types

The data types needed to simulate the trees are given in the following
module. The difference with respec to the previous model is that Internodes and
Leaves have optical properties needed for ray tracing (they are defined as
Lambertian surfaces).

=#
## Data types
module TreeTypes
    using VirtualPlantLab
    using Distributions
    ## Meristem
    Base.@kwdef mutable struct Meristem <: VirtualPlantLab.Node
        age::Int64 = 0   ## Age of the meristem
    end
    ## Bud
    struct Bud <: VirtualPlantLab.Node end
    ## Node
    struct Node <: VirtualPlantLab.Node end
    ## BudNode
    struct BudNode <: VirtualPlantLab.Node end
    ## Internode (needs to be mutable to allow for changes over time)
    Base.@kwdef mutable struct Internode <: VirtualPlantLab.Node
        age::Int64 = 0         ## Age of the internode
        biomass::Float64 = 0.0 ## Initial biomass
        length::Float64 = 0.0  ## Internodes
        width::Float64  = 0.0  ## Internodes
        sink::Exponential{Float64} = Exponential(5)
        material::Lambertian{1} = Lambertian(τ = 0.1, ρ = 0.05) ## Leaf material
    end
    ## Leaf
    Base.@kwdef mutable struct Leaf <: VirtualPlantLab.Node
        age::Int64 = 0         ## Age of the leaf
        biomass::Float64 = 0.0 ## Initial biomass
        length::Float64 = 0.0  ## Leaves
        width::Float64 = 0.0   ## Leaves
        sink::Beta{Float64} = Beta(2,5)
        material::Lambertian{1} = Lambertian(τ = 0.1, ρ = 0.05) ## Leaf material
    end
    ## Graph-level variables -> mutable because we need to modify them during growth
    Base.@kwdef mutable struct treeparams
        ## Variables
        PAR::Float64 = 0.0   ## Total PAR absorbed by the leaves on the tree (MJ)
        biomass::Float64 = 2e-3 ## Current total biomass (g)
        ## Parameters
        RUE::Float64 = 5.0   ## Radiation use efficiency (g/MJ) -> unrealistic to speed up sim
        IB0::Float64 = 1e-3  ## Initial biomass of an internode (g)
        SIW::Float64 = 0.1e6 ## Specific internode weight (g/m3)
        IS::Float64  = 15.0  ## Internode shape parameter (length/width)
        LB0::Float64 = 1e-3  ## Initial biomass of a leaf
        SLW::Float64 = 100.0 ## Specific leaf weight (g/m2)
        LS::Float64  = 3.0   ## Leaf shape parameter (length/width)
        budbreak::Float64 = 1/0.5 ## Bud break probability coefficient (in 1/m)
        plastochron::Int64 = 5 ## Number of days between phytomer production
        leaf_expansion::Float64 = 15.0 ## Number of days that a leaf expands
        phyllotaxis::Float64 = 140.0
        leaf_angle::Float64 = 30.0
        branch_angle::Float64 = 45.0
    end
end

import .TreeTypes
#=

### Geometry

The methods for creating the geometry and color of the tree are the same as in
the previous example but include the materials for the ray tracer.

=#
## Create geometry + color for the internodes
function VirtualPlantLab.feed!(turtle::Turtle, i::TreeTypes.Internode, data)
    ## Rotate turtle around the head to implement elliptical phyllotaxis
    rh!(turtle, data.phyllotaxis)
    HollowCylinder!(turtle, length = i.length, height = i.width, width = i.width,
                move = true, color = RGB(0.5,0.4,0.0), material = i.material)
    return nothing
end

## Create geometry + color for the leaves
function VirtualPlantLab.feed!(turtle::Turtle, l::TreeTypes.Leaf, data)
    ## Rotate turtle around the arm for insertion angle
    ra!(turtle, -data.leaf_angle)
    ## Generate the leaf
    Ellipse!(turtle, length = l.length, width = l.width, move = false,
             color = RGB(0.2,0.6,0.2), material = l.material)
    ## Rotate turtle back to original direction
    ra!(turtle, data.leaf_angle)
    return nothing
end

## Insertion angle for the bud nodes
function VirtualPlantLab.feed!(turtle::Turtle, b::TreeTypes.BudNode, data)
    ## Rotate turtle around the arm for insertion angle
    ra!(turtle, -data.branch_angle)
end
#=

### Development

The meristem rule is now parameterized by the initial states of the leaves and
internodes and will only be triggered every X days where X is the plastochron.

=#
## Create right side of the growth rule (parameterized by the initial states
## of the leaves and internodes)
function create_meristem_rule(vleaf, vint)
    meristem_rule = Rule(TreeTypes.Meristem,
                        lhs = mer -> mod(data(mer).age, graph_data(mer).plastochron) == 0,
                        rhs = mer -> TreeTypes.Node() +
                                     (TreeTypes.Bud(),
                                     TreeTypes.Leaf(biomass = vleaf.biomass,
                                                    length  = vleaf.length,
                                                    width   = vleaf.width)) +
                                     TreeTypes.Internode(biomass = vint.biomass,
                                                         length  = vint.length,
                                                         width   = vint.width) +
                                     TreeTypes.Meristem())
end
#=

The bud break probability is now a function of distance to the apical meristem
rather than the number of internodes. An adhoc traversal is used to compute this
length of the main branch a bud belongs to (ignoring the lateral branches).

=#
# Compute the probability that a bud breaks as function of distance to the meristem
function prob_break(bud)
    ## We move to parent node in the branch where the bud was created
    node =  parent(bud)
    ## Extract the first internode
    child = filter(x -> data(x) isa TreeTypes.Internode, children(node))[1]
    data_child = data(child)
    ## We measure the length of the branch until we find the meristem
    distance = 0.0
    while !isa(data_child, TreeTypes.Meristem)
        ## If we encounter an internode, store the length and move to the next node
        if data_child isa TreeTypes.Internode
            distance += data_child.length
            child = children(child)[1]
            data_child = data(child)
        ## If we encounter a node, extract the next internode
        elseif data_child isa TreeTypes.Node
                child = filter(x -> data(x) isa TreeTypes.Internode, children(child))[1]
                data_child = data(child)
        else
            error("Should be Internode, Node or Meristem")
        end
    end
    ## Compute the probability of bud break as function of distance and
    ## make stochastic decision
    prob =  min(1.0, distance*graph_data(bud).budbreak)
    return rand() < prob
end

## Branch rule parameterized by initial states of internodes
function create_branch_rule(vint)
    branch_rule = Rule(TreeTypes.Bud,
            lhs = prob_break,
            rhs = bud -> TreeTypes.BudNode() +
                         TreeTypes.Internode(biomass = vint.biomass,
                                             length  = vint.length,
                                             width   = vint.width) +
                         TreeTypes.Meristem())
end
#=

### Light interception

As growth is now dependent on intercepted PAR via RUE, we now need to simulate
light interception by the trees. We will use a ray-tracing approach to do so.
The first step is to create a scene with the trees and the light sources. As for
rendering, the scene can be created from the `forest` object by simply calling
`Scene(forest)` that will generate the 3D meshes and connect them to their
optical properties.

However, we also want to add the soil surface as this will affect the light
distribution within the scene due to reflection from the soil surface. This is
similar to the customized scene that we created before for rendering, but now
for the light simulation.

=#
function create_soil()
    soil = Rectangle(length = 21.0, width = 21.0)
    rotatey!(soil, π/2) ## To put it in the XY plane
    VirtualPlantLab.translate!(soil, Vec(0.0, 10.5, 0.0)) ## Corner at (0,0,0)
    return soil
end
function create_scene(forest)
    ## These are the trees
    scene = Scene(vec(forest))
    ## Add a soil surface
    soil = create_soil()
    soil_material = Lambertian(τ = 0.0, ρ = 0.21)
    add!(scene, mesh = soil, material = soil_material)
    ## Return the scene
    return scene
end
#=

Given the scene, we can create the light sources that can approximate the solar
irradiance on a given day, location and time of the day using the functions from
the  package (see package documentation for details). Given the latitude,
day of year and fraction of the day (`f = 0` being sunrise and `f = 1` being sunset),
the function `clear_sky()` computes the direct and diffuse solar radiation assuming
a clear sky. These values may be converted to different wavebands and units using
`waveband_conversion()`. Finally, the collection of light sources approximating
the solar irradiance distribution over the sky hemisphere is constructed with the
function `sky()` (this last step requires the 3D scene as input in order to place
the light sources adequately).

=#
function create_sky(;scene, lat = 52.0*π/180.0, DOY = 182)
    ## Fraction of the day and day length
    fs = collect(0.1:0.1:0.9)
    dec = declination(DOY)
    DL = day_length(lat, dec)*3600
    ## Compute solar irradiance
    temp = [clear_sky(lat = lat, DOY = DOY, f = f) for f in fs] # W/m2
    Ig   = getindex.(temp, 1)
    Idir = getindex.(temp, 2)
    Idif = getindex.(temp, 3)
    ## Conversion factors to PAR for direct and diffuse irradiance
    f_dir = waveband_conversion(Itype = :direct,  waveband = :PAR, mode = :power)
    f_dif = waveband_conversion(Itype = :diffuse, waveband = :PAR, mode = :power)
    ## Actual irradiance per waveband
    Idir_PAR = f_dir.*Idir
    Idif_PAR = f_dif.*Idif
    ## Create the dome of diffuse light
    dome = sky(scene,
                  Idir = 0.0, ## No direct solar radiation
                  Idif = sum(Idir_PAR)/10*DL, ## Daily Diffuse solar radiation
                  nrays_dif = 1_000_000, ## Total number of rays for diffuse solar radiation
                  sky_model = StandardSky, ## Angular distribution of solar radiation
                  dome_method = equal_solid_angles, ## Discretization of the sky dome
                  ntheta = 9, ## Number of discretization steps in the zenith angle
                  nphi = 12) ## Number of discretization steps in the azimuth angle
    ## Add direct sources for different times of the day
    for I in Idir_PAR
        push!(dome, sky(scene, Idir = I/10*DL, nrays_dir = 100_000, Idif = 0.0)[1])
    end
    return dome
end
#=

The 3D scene and the light sources are then combined into a `RayTracer` object,
together with general settings for the ray tracing simulation chosen via `RTSettings()`.
The most important settings refer to the Russian roulette system and the grid
cloner (see section on Ray Tracing for details). The settings for the Russian
roulette system include the number of times a ray will be traced
deterministically (`maxiter`) and the probability that a ray that exceeds `maxiter`
is terminated (`pkill`). The grid cloner is used to approximate an infinite canopy
by replicating the scene in the different directions (`nx` and `ny` being the
number of replicates in each direction along the x and y axes, respectively). It
is also possible to turn on parallelization of the ray tracing simulation by
setting `parallel = true` (currently this uses Julia's builtin multithreading
capabilities).

In addition `RTSettings()`, an acceleration structure and a splitting rule can
be defined when creating the `RayTracer` object (see ray tracing documentation
for details). The acceleration structure allows speeding up the ray tracing
by avoiding testing all rays against all objects in the scene.

=#
function create_raytracer(scene, sources)
    settings = RTSettings(pkill = 0.9, maxiter = 4, nx = 5, ny = 5, parallel = true)
    RayTracer(scene, sources, settings = settings, acceleration = BVH,
                     rule = SAH{3}(5, 10));
end
#=

The actual ray tracing simulation is performed by calling the `trace!()` method
on the ray tracing object. This will trace all rays from all light sources and
update the radiant power absorbed by the different surfaces in the scene inside
the `Material` objects (see `feed!()` above):

=#
function run_raytracer!(forest; DOY = 182)
    scene   = create_scene(forest)
    sources = create_sky(scene = scene, DOY = DOY)
    rtobj   = create_raytracer(scene, sources)
    trace!(rtobj)
    return nothing
end
#=

The total PAR absorbed for each tree is calculated from the material objects of
the different internodes (using `power()` on the `Material` object). Note that
the `power()` function returns three different values, one for each waveband,
but they are added together as RUE is defined for total PAR.


=#
# Run the ray tracer, calculate PAR absorbed per tree and add it to the daily
# total using general weighted quadrature formula
function calculate_PAR!(forest;  DOY = 182)
    ## Reset PAR absorbed by the tree (at the start of a new day)
    reset_PAR!(forest)
    ## Run the ray tracer to compute daily PAR absorption
    run_raytracer!(forest, DOY = DOY)
    ## Add up PAR absorbed by each leaf within each tree
    @threads for tree in forest
        for l in get_leaves(tree)
            data(tree).PAR += power(l.material)[1]
        end
    end
    return nothing
end

# Reset PAR absorbed by the tree (at the start of a new day)
function reset_PAR!(forest)
    for tree in forest
        data(tree).PAR = 0.0
    end
    return nothing
end
#=

### Growth

We need some functions to compute the length and width of a leaf or internode
from its biomass

=#
function leaf_dims(biomass, vars)
    leaf_biomass = biomass
    leaf_area    = biomass/vars.SLW
    leaf_length  = sqrt(leaf_area*4*vars.LS/pi)
    leaf_width   = leaf_length/vars.LS
    return leaf_length, leaf_width
end

function int_dims(biomass, vars)
    int_biomass = biomass
    int_volume  = biomass/vars.SIW
    int_length  = cbrt(int_volume*4*vars.IS^2/pi)
    int_width   = int_length/vars.IS
    return int_length, int_width
end
#=

Each day, the total biomass of the tree is updated using a simple RUE formula
and the increment of biomass is distributed across the organs proportionally to
their relative sink strength (of leaves or internodes).

The sink strength of leaves is modelled with a beta distribution scaled to the
`leaf_expansion` argument that determines the duration of leaf growth, whereas
for the internodes it follows a negative exponential distribution. The `pdf`
function computes the probability density of each distribution which is taken as
proportional to the sink strength (the model is actually source-limited since we
imposed a particular growth rate).

=#
sink_strength(leaf, vars) = leaf.age > vars.leaf_expansion ? 0.0 :
                            pdf(leaf.sink, leaf.age/vars.leaf_expansion)/100.0
plot(0:1:50, x -> sink_strength(TreeTypes.Leaf(age = x), TreeTypes.treeparams()),
     xlabel = "Age", ylabel = "Sink strength", label = "Leaf")
#=

=#
sink_strength(int) = pdf(int.sink, int.age)
plot!(0:1:50, x -> sink_strength(TreeTypes.Internode(age = x)), label = "Internode")
#=

Now we need a function that updates the biomass of the tree, allocates it to the
different organs and updates the dimensions of said organs. For simplicity,
we create the functions `leaves()` and `internodes()` that will apply the queries
to the tree required to extract said nodes:

=#
get_leaves(tree) = apply(tree, Query(TreeTypes.Leaf))
get_internodes(tree) = apply(tree, Query(TreeTypes.Internode))
#=

The age of the different organs is updated every time step:

=#
function age!(all_leaves, all_internodes, all_meristems)
    for leaf in all_leaves
        leaf.age += 1
    end
    for int in all_internodes
        int.age += 1
    end
    for mer in all_meristems
        mer.age += 1
    end
    return nothing
end
#=

The daily growth is allocated to different organs proportional to their sink
strength.

=#
function grow!(tree, all_leaves, all_internodes)
    ## Compute total biomass increment
    tdata = data(tree)
    ΔB    = max(0.5, tdata.RUE*tdata.PAR/1e6) # Trick to emulate reserves in seedling
    tdata.biomass += ΔB
    ## Total sink strength
    total_sink = 0.0
    for leaf in all_leaves
        total_sink += sink_strength(leaf, tdata)
    end
    for int in all_internodes
        total_sink += sink_strength(int)
    end
    ## Allocate biomass to leaves and internodes
    for leaf in all_leaves
        leaf.biomass += ΔB*sink_strength(leaf, tdata)/total_sink
    end
    for int in all_internodes
        int.biomass += ΔB*sink_strength(int)/total_sink
    end
    return nothing
end
#=

Finally, we need to update the dimensions of the organs. The leaf dimensions are

=#
function size_leaves!(all_leaves, tvars)
    for leaf in all_leaves
        leaf.length, leaf.width = leaf_dims(leaf.biomass, tvars)
    end
    return nothing
end
function size_internodes!(all_internodes, tvars)
    for int in all_internodes
        int.length, int.width = int_dims(int.biomass, tvars)
    end
    return nothing
end
#=

### Daily step

All the growth and developmental functions are combined together into a daily
step function that updates the forest by iterating over the different trees in
parallel.

=#
get_meristems(tree) = apply(tree, Query(TreeTypes.Meristem))
function daily_step!(forest, DOY)
    ## Compute PAR absorbed by each tree
    calculate_PAR!(forest, DOY = DOY)
    ## Grow the trees
    @threads for tree in forest
        ## Retrieve all the relevant organs
        all_leaves = get_leaves(tree)
        all_internodes = get_internodes(tree)
        all_meristems = get_meristems(tree)
        ## Update the age of the organs
        age!(all_leaves, all_internodes, all_meristems)
        ## Grow the tree
        grow!(tree, all_leaves, all_internodes)
        tdata = data(tree)
        size_leaves!(all_leaves, tdata)
        size_internodes!(all_internodes, tdata)
        ## Developmental rules
        rewrite!(tree)
    end
end
#=

### Initialization

The trees are initialized on a regular grid with random values for the initial
orientation and RUE:

=#
RUEs = rand(Normal(1.5,0.2), 10, 10)
histogram(vec(RUEs))
#=

=#
orientations = [rand()*360.0 for i = 1:2.0:20.0, j = 1:2.0:20.0]
histogram(vec(orientations))
#=

=#
origins = [Vec(i,j,0) for i = 1:2.0:20.0, j = 1:2.0:20.0];
#=

The following initalizes a tree based on the origin, orientation and RUE:

=#
function create_tree(origin, orientation, RUE)
    ## Initial state and parameters of the tree
    data = TreeTypes.treeparams(RUE = RUE)
    ## Initial states of the leaves
    leaf_length, leaf_width = leaf_dims(data.LB0, data)
    vleaf = (biomass = data.LB0, length = leaf_length, width = leaf_width)
    ## Initial states of the internodes
    int_length, int_width = int_dims(data.LB0, data)
    vint = (biomass = data.IB0, length = int_length, width = int_width)
    ## Growth rules
    meristem_rule = create_meristem_rule(vleaf, vint)
    branch_rule   = create_branch_rule(vint)
    axiom = T(origin) + RH(orientation) +
            TreeTypes.Internode(biomass = vint.biomass,
                                length  = vint.length,
                                width   = vint.width) +
            TreeTypes.Meristem()
    tree = Graph(axiom = axiom, rules = (meristem_rule, branch_rule),
                 data = data)
    return tree
end
#=


## Visualization

As in the previous example, it makes sense to visualize the forest with a soil
tile beneath it. Unlike in the previous example, we will construct the soil tile
using a dedicated graph and generate a `Scene` object which can later be
merged with the rest of scene generated in daily step:

=#
Base.@kwdef struct Soil <: VirtualPlantLab.Node
    length::Float64
    width::Float64
end
function VirtualPlantLab.feed!(turtle::Turtle, s::Soil, data)
    Rectangle!(turtle, length = s.length, width = s.width, color = RGB(255/255, 236/255, 179/255))
end
soil_graph = RA(-90.0) + T(Vec(0.0, 10.0, 0.0)) + ## Moves into position
             Soil(length = 20.0, width = 20.0) ## Draws the soil tile
soil = Scene(Graph(axiom = soil_graph));
render(soil, axes = false)
#=

And the following function renders the entire scene (notice that we need to
use `display()` to force the rendering of the scene when called within a loop
or a function):

=#
function render_forest(forest, soil)
    scene = Scene(vec(forest)) ## create scene from forest
    scene = Scene([scene, soil]) ## merges the two scenes
    display(render(scene))
end
#=

## Simulation

We can now create a forest of trees on a regular grid:

=#
forest = create_tree.(origins, orientations, RUEs);
render_forest(forest, soil)
start = 180
for i in 1:20
    println("Day $i")
    daily_step!(forest, i + start)
    if mod(i, 5) == 0
        render_forest(forest, soil)
    end
end
