using VPL
using Test
using Aqua

# Aqua
@testset "Aqua" begin
    Aqua.test_all(VPL, ambiguities = false)
    Aqua.test_ambiguities([VPL])
end

# Tutorials
@testset "Tutorials" begin
    @testset "Algae" begin include("algae.jl") end
    @testset "Snowflakes" begin include("snowflakes.jl") end
    @testset "Tree" begin include("tree.jl") end
    @testset "Forest" begin include("forest.jl") end
    @testset "Growth forest" begin include("growthforest.jl") end
    @testset "Raytraced forest" begin include("raytracedforest.jl") end
    @testset "Context" begin include("context.jl") end
    @testset "Relational queries" begin include("relationalqueries.jl") end
end
