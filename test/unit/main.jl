@testset "Optimized 1Tree" begin
    module_path = dirname(pathof(TSPSolver))
    println(module_path)
    tree, lb = TSPSolver.optimize(joinpath(module_path, "../test/data/bier127.tsp"))
    @test lb < 118293.52381566973
end