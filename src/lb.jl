"""
    get_optimized_1tree(cost)

Obtain an optimized 1tree given the cost matrix. This calls [`get_1tree`](@ref) and then adds extra 
benefits for each point which has only one edge to make it more likely in the next run of [`get_1tree`](@ref) 
that the point will have two edges. A negative benefit is used for points which have more than two edges.

Return the tree as a list of edges and the cost of the tree.
"""
function get_optimized_1tree(original_cost; runs=10)
    cost = deepcopy(original_cost)
    N = size(cost, 1)
    tree, lb = get_1tree(cost)
    degrees = zeros(Int, N)
    point_benefit = zeros(Float64, N)
    extra_cost = 0.0
    non_inf_cost = filter(c->!isinf(c), cost)
    max_cost = maximum(non_inf_cost)

    cost_factor = max_cost/N
    for _ in 1:runs
        degrees .= 0
        point_benefit .= 0.0
        for edge in tree
            degrees[edge.src] += 1
            degrees[edge.dst] += 1
        end
        # if each degree is 2 we found a tour
        if all(x->x==2, degrees)
            return tree, lb+extra_cost, true 
        end
        for i in 1:N
            point_benefit[i] = cost_factor*(2-degrees[i])
            cost[i, :] .-= point_benefit[i]
            cost[:, i] .-= point_benefit[i]
        end
        extra_cost = 2*sum(point_benefit)
        tree, lb = get_1tree(cost)
        cost_factor *= 0.9
    end

    return tree, lb+extra_cost, false 
end

"""
    get_1tree(cost)

Get a 1tree and cost of it based on a given cost matrix.
Create an MST first for the first 1 to N-1 points and then add two edges which connects the Nth point to its two nearest neighbors.

Can be optimized by adding extra costs with [`get_optimized_1tree`](@ref) which obtains a better lower bound.

Return the tree as a list of edges and the cost which can be used as the lower bound for the TSP problem.
"""
function get_1tree(cost)
    N = size(cost, 1)
   
    tree = prim_mst(complete_graph(N-1), cost)
    
    mst_cost = get_edges_cost(cost, tree)
    
    # extra cost for the two edges from the last point to the two nearest neighbors
    nearest_neighbors = partialsortperm(cost[N,:], 1:3)
    n_actual_neighbors = 0
    extra_costs = 0.0
    for neighbor in nearest_neighbors
        n_actual_neighbors == 2 && break
        if neighbor != N
            n_actual_neighbors += 1
            push!(tree, Edge(N, neighbor))
            extra_costs += cost[N, neighbor]
        end
    end

    lb = mst_cost + extra_costs

    return tree, lb
end
