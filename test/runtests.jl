using VPL
using Test
using Aqua

# Aqua
@testset "Aqua" begin
    Aqua.test_all(VPL, ambiguities = false)
    Aqua.test_ambiguities([VPL])
end
