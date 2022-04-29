"""
    get_optimized_1tree(cost)

Obtain an optimized 1tree given the cost matrix. This calls [`get_1tree`](@ref) and then adds extra 
benefits for each point which has only one edge to make it more likely in the next run of [`get_1tree`](@ref) 
that the point will have two edges. A negative benefit is used for points which have more than two edges.

Return the tree as a list of edges and the cost of the tree.
"""
function get_optimized_1tree(original_g; runs=10)
    g = deepcopy(original_g)
    N = nv(g)
    tree, lb = get_1tree(g)
    degrees = zeros(Int, N)
    point_benefit = zeros(Float64, N)
    extra_cost = 0.0
    max_cost = maximum(weights(g))

    cost_factor = max_cost/N
    for _ in 1:runs
        degrees .= 0
        point_benefit .= 0.0
        for edge in tree
            degrees[edge.src] += 1
            degrees[edge.dst] += 1
        end
        for i in 1:N
            point_benefit[i] = cost_factor*(2-degrees[i])
            for neighbor in neighbors(g, i)
                cost = get_prop(g, i, neighbor, :weight)
                set_prop!(g, i, neighbor, :weight, cost-point_benefit[i])
            end
        end
        extra_cost = 2*sum(point_benefit)
        tree, lb = get_1tree(g)
        cost_factor *= 0.9
    end

    return tree, lb+extra_cost 
end

"""
    get_1tree(g)

Get a 1tree and cost of it based on a given graph.
Create an MST first for the first 1 to N-1 points and then add two edges which connects the Nth point to its two nearest neighbors.

Can be optimized by adding extra costs with [`get_optimized_1tree`](@ref) which obtains a better lower bound.

Return the tree as a list of edges and the cost which can be used as the lower bound for the TSP problem.
"""
function get_1tree(g)
    N = nv(g)
    last_neighbors = collect(neighbors(g, N))
    weights_last_neighbors = [get_prop(g, N, n, :weight) for n in last_neighbors]
    # temporary remove that last node for the mst
    rem_vertex!(g, N)
    tree = prim_mst(g)
    
    mst_cost = get_edges_cost(g, tree)
    # add edges back in
    @assert add_vertex!(g)
    for i in 1:length(last_neighbors)
        add_edge!(g, N, last_neighbors[i], :weight, weights_last_neighbors[i])
    end
    # extra cost for the two edges from the last point to the two nearest neighbors
    nearest_neighbors = partialsortperm(weights_last_neighbors, 1:3)
    n_actual_neighbors = 0
    extra_costs = 0.0
    for neighbor in nearest_neighbors
        n_actual_neighbors == 2 && break
        if neighbor != N
            n_actual_neighbors += 1
            push!(tree, Edge(N, neighbor))
            extra_costs += get_prop(g, neighbor, N, :weight)
        end
    end

    lb = mst_cost + extra_costs

    return tree, lb
end
