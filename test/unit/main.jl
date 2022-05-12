@testset "Optimized 1Tree" begin
    module_path = dirname(pathof(TSPSolver))
    g = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    root = TSPSolver.Root(g)

    tree, lb = TSPSolver.get_optimized_1tree(root.cost)
    @show lb
    @test lb < 118293.52381566973

    TSPSolver.fix_edge!(root, (2, 3))
    TSPSolver.fix_edge!(root, (2, 5))
    tree, lb = TSPSolver.get_optimized_1tree(root.cost)
    @test Edge(2,3) in tree || Edge(3,2) in tree
    @test Edge(2,5) in tree || Edge(5,2) in tree
end

@testset "Greedy" begin
    module_path = dirname(pathof(TSPSolver))
    g = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    root = TSPSolver.Root(g)
    original_root = deepcopy(root)

    @time tour, ub = TSPSolver.greedy(root.g)
    @show ub
    @test length(tour) == nv(g)
    @test ub > 118293.52381566973

    # fix the first edges as it was in greedy anyway
    v1, v2 = tour[1], tour[2]
    extra_cost = TSPSolver.fix_edge!(root, (v1, v2))
    new_tour, new_ub = TSPSolver.greedy(root.g)
    @test new_ub + extra_cost ≈ ub    
    @test new_tour == tour
    
    # fix a couple of edges and check that they were fixed correctly
    root = deepcopy(original_root)
    fixed_edges = zeros(Int, nv(g))
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8
    extra_cost = 0.0
    extra_cost += TSPSolver.fix_edge!(root, (1,2))
    extra_cost += TSPSolver.fix_edge!(root, (2,3))
    extra_cost += TSPSolver.fix_edge!(root, (4,8))
    tour, ub = TSPSolver.greedy(root.g)
    ub += extra_cost
    c = 0
    for i in 1:nv(g)
        if fixed_edges[tour[i]] != 0
            c += 1
            @test tour[i+1] == fixed_edges[tour[i]]
        end
    end
    @test c == count(i->i!=0, fixed_edges)

    # fix a couple of edges and check that they were fixed correctly 
    # also disallow some edges 
    root = deepcopy(original_root)
    fixed_edges = zeros(Int, nv(root.g))
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8
    extra_cost = 0.0
    extra_cost += TSPSolver.fix_edge!(root, (1,2))
    extra_cost += TSPSolver.fix_edge!(root, (2,3))
    extra_cost += TSPSolver.fix_edge!(root, (4,8))

    disallow_edges = Dict{Int, Set{Int}}()
    N = nv(g)
    disallow_edges[7] = Set([i for i in 1:N if !(i in [2,3,8,9])])
    for i in 1:N
        i in [2,3,8,9] && continue
        TSPSolver.disallow_edge!(root, (7, i))
    end
    
    tour, ub = TSPSolver.greedy(root.g)
    ub += extra_cost
    if tour === nothing 
        @test isnan(ub)
    else
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
    end
end