using TSPSolver
using Bonobo
using Test

using Graphs
using MetaGraphs

@testset "TSPSolver.jl" begin
    
    include("end2end/berlin52.jl")
    include("unit/main.jl")
end
