@testset "Optimized 1Tree" begin
    module_path = dirname(pathof(TSPSolver))
    points = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    N = length(points)
    cost = [TSPSolver.euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]

    tree, lb = TSPSolver.get_optimized_1tree(cost)
    @test lb < 118293.52381566973
end

@testset "1tree" begin
    module_path = dirname(pathof(TSPSolver))
    points = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    N = length(points)
    cost = [TSPSolver.euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]

    tree, lb = TSPSolver.get_1tree(cost, zeros((N, N)))

    # fix the first two edges as in the tree
    fixed_edges = zeros(Int, N)
    fixed_edges[tree[1].src] = tree[1].dst
    fixed_edges[tree[2].src] = tree[2].dst

    fix_disallow_costs = TSPSolver.get_fix_disallow_costs(fixed_edges, Dict{Int, Set{Int}}())

    new_tree, new_lb = TSPSolver.get_1tree(cost, fix_disallow_costs)
    @test new_tree == tree
    @test new_lb ≈ lb

    # fix the first two edges as in the tree and disallow some that weren't used
    fixed_edges = zeros(Int, N)
    fixed_edges[tree[1].src] = tree[1].dst
    fixed_edges[tree[2].src] = tree[2].dst

    disallow_edges = Dict{Int, Set{Int}}()
    five_connected_to = []
    for edge in tree
        if edge.src == 5
            push!(five_connected_to, edge.dst)
        end
        if edge.dst == 5
            push!(five_connected_to, edge.src)
        end
    end

    disallow_edges[5] = Set([i for i in 1:N if !(i in five_connected_to)])

    fix_disallow_costs = TSPSolver.get_fix_disallow_costs(fixed_edges, disallow_edges)

    new_tree, new_lb = TSPSolver.get_1tree(cost, fix_disallow_costs)
    @test new_tree == tree
    @test new_lb ≈ lb


end

@testset "Greedy" begin
    module_path = dirname(pathof(TSPSolver))
    points = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    N = length(points)
    cost = [TSPSolver.euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]

    tour, lb = TSPSolver.greedy(cost)
    @test length(tour) == N
    @test lb > 118293.52381566973

    # fix the first edges as it was in greedy anyway
    fixed_edges = zeros(Int, N)
    fixed_edges[tour[1]] = tour[2]
    new_tour, new_lb = TSPSolver.greedy(cost, fixed_edges)
    @test new_lb ≈ lb    
    @test new_tour == tour 
    
    # fix a couple of edges and check that they were fixed correctly
    fixed_edges = zeros(Int, N)
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8
    tour, lb = TSPSolver.greedy(cost, fixed_edges)
    c = 0
    for i in 1:N
        if fixed_edges[tour[i]] != 0
            c += 1
            @test tour[i+1] == fixed_edges[tour[i]]
        end
    end
    @test c == count(i->i!=0, fixed_edges)

    # fix a couple of edges and check that they were fixed correctly 
    # also disallow some edges 
    fixed_edges = zeros(Int, N)
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8

    disallow_edges = Dict{Int, Set{Int}}()
    disallow_edges[7] = Set([i for i in 1:N if !(i in [2,3,8,9])])
    
    tour, lb = TSPSolver.greedy(cost, fixed_edges, disallow_edges)
    c = 0
    for i in 1:N
        if fixed_edges[tour[i]] != 0
            c += 1
            @test tour[i+1] == fixed_edges[tour[i]]
        end

        if tour[i] == 7
            if i + 1 <= N
                @test tour[i+1] == 9 # only 9 is not 
            else
                @test tour[1] == 9
            end
        end
    end
    @test c == count(i->i!=0, fixed_edges)

    # disallow too many edges
    fixed_edges = zeros(Int, N)
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8

    disallow_edges = Dict{Int, Set{Int}}()
    disallow_edges[7] = Set([i for i in 1:N if !(i in [2,3,8])])
    
    tour, lb = TSPSolver.greedy(cost, fixed_edges, disallow_edges)
    @test tour === nothing
    @test isnan(lb)

    # fix the same dst twice
    fixed_edges = zeros(Int, N)
    fixed_edges[1] = 2
    fixed_edges[2] = 8
    fixed_edges[4] = 8

    tour, lb = TSPSolver.greedy(cost, fixed_edges)
    @test tour === nothing
    @test isnan(lb)
end