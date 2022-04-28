@testset "Optimized 1Tree" begin
    module_path = dirname(pathof(TSPSolver))
    g = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))

    tree, lb = TSPSolver.get_optimized_1tree(g)
    @show lb
    @time tree, lb = TSPSolver.get_optimized_1tree(g)
    @test lb < 118293.52381566973
end

@testset "Greedy" begin
    module_path = dirname(pathof(TSPSolver))
    g = TSPSolver.simple_parse_tsp(joinpath(module_path, "../test/data/bier127.tsp"))
    original_g = deepcopy(g)

    @time tour, ub = TSPSolver.greedy(g)
    @show ub
    @test length(tour) == nv(g)
    @test ub > 118293.52381566973

    # fix the first edges as it was in greedy anyway
    v1, v2 = tour[1], tour[2]
    extra_cost = TSPSolver.fix_edge!(g, (v1, v2))
    new_tour, new_ub = TSPSolver.greedy(g, extra_cost)
    @test new_ub ≈ ub    
    @test new_tour == tour
    
    # fix a couple of edges and check that they were fixed correctly
    g = deepcopy(original_g)
    fixed_edges = zeros(Int, nv(g))
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8
    extra_cost = 0.0
    extra_cost += TSPSolver.fix_edge!(g, (1,2))
    extra_cost += TSPSolver.fix_edge!(g, (2,3))
    extra_cost += TSPSolver.fix_edge!(g, (4,8))
    tour, ub = TSPSolver.greedy(g, extra_cost)
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
    g = deepcopy(original_g)
    fixed_edges = zeros(Int, nv(g))
    fixed_edges[1] = 2
    fixed_edges[2] = 3
    fixed_edges[4] = 8
    extra_cost = 0.0
    extra_cost += TSPSolver.fix_edge!(g, (1,2))
    extra_cost += TSPSolver.fix_edge!(g, (2,3))
    extra_cost += TSPSolver.fix_edge!(g, (4,8))

    disallow_edges = Dict{Int, Set{Int}}()
    N = nv(g)
    disallow_edges[7] = Set([i for i in 1:N if !(i in [2,3,8,9])])
    for i in 1:N
        i in [2,3,8,9] && continue
        rem_edge!(g, 7, i)
    end
    
    tour, ub = TSPSolver.greedy(g, extra_cost)
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