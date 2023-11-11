using VirtualPlantLab
using Test
using Aqua

# Aqua
@testset "Aqua" begin
    Aqua.test_all(VirtualPlantLab, ambiguities = false)
    Aqua.test_ambiguities([VirtualPlantLab])
end

# Tutorials
@testset "Tutorials" begin
    @testset "Algae" begin
        let
            include("algae.jl")
        end
    end
    @testset "Snowflakes" begin
        let
            include("snowflakes.jl")
        end
    end
    @testset "Tree" begin
        let
            include("tree.jl")
        end
    end
    @testset "Forest" begin
        let
            include("forest.jl")
        end
    end
    @testset "Growth forest" begin
        let
            include("growthforest.jl")
        end
    end
    @testset "Raytraced forest" begin
        let
            include("raytracedforest.jl")
        end
    end
    @testset "Context" begin
        let
            include("context.jl")
        end
    end
    @testset "Relational queries" begin
        let
            include("relationalqueries.jl")
        end
    end
end
