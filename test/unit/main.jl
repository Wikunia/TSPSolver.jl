@testset "Optimized 1Tree" begin
    module_path = dirname(pathof(TSPSolver))
    points = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    N = length(points)
    cost = [TSPSolver.euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]

    tree, lb = TSPSolver.get_optimized_1tree(cost)
    @test lb < 118293.52381566973
end

@testset "Greedy" begin
    module_path = dirname(pathof(TSPSolver))
    points = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    N = length(points)
    cost = [TSPSolver.euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]

    tree, lb = TSPSolver.greedy(points, cost)
    @test lb > 118293.52381566973
end