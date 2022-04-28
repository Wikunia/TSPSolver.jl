"""
    simple_parse_tsp(filename; verbose = true)

Try to parse the ".tsp" file given by `filename`. Very simple implementation
just to be able to test the optimization; may break on other files. Returns a
graph of cities and edges for use in `get_optimal_tour`.
"""
function simple_parse_tsp(filename; verbose = false)
    cities = Vector{Tuple{Float64, Float64}}()
    section = :Meta
    for line in readlines(filename)
        line = strip(line)
        line == "EOF" && break       
        if section == :Meta && verbose 
            println(line)
        end
        if section == :NODE_COORD_SECTION
            nums = split(line)
            @assert length(nums) == 3
            x = parse(Float64, nums[2])
            y = parse(Float64, nums[3])
            push!(cities, (x, y))
        end
        # change section type
        if line == "NODE_COORD_SECTION"
            section = :NODE_COORD_SECTION
        end
    end

    N = length(cities)
    g = MetaGraph(N)
    for i in 1:N
        for j in i+1:N
            add_edge!(g, i, j, :weight, euclidean_distance(cities[i], cities[j]))
        end
    end

    return g
end

"""
    get_edges_cost(edges, cost_mat)

Return the sum of the cost of the edges
"""
function get_edges_cost(g, edges)
    edges_cost = 0.0
    for edge in edges
        edges_cost += get_prop(g, edge.src, edge.dst, :weight) 
    end
    return edges_cost
end

"""
    get_tour_cost(tour, cost_mat)

Return the cost of the tour for example with `tour = [1,3,5]`
the sum would be `cost_mat[1,3]+cost_mat[3,5]+cost_mat[5,1]`.
"""
function get_tour_cost(tour, cost_mat)
    cost = 0.0
    for i in 1:length(tour)-1
        src = tour[i]
        dst = tour[i+1]
        cost += cost_mat[src,dst]
    end
    cost += cost_mat[tour[end],tour[1]]
    return cost
end

function get_tour_cost(g, tour)
    cost = 0.0
    for i in 1:length(tour)-1
        src = tour[i]
        dst = tour[i+1]
        cost += get_prop(g, src, dst, :weight)
    end
    cost += get_prop(g, tour[end], tour[1], :weight)
    return cost
end

"""
    euclidean_distance(point1, point2)

The usual Euclidean distance measure.
Copied from https://github.com/ericphanson/TravelingSalesmanExact.jl
"""
euclidean_distance(point1, point2) = sqrt((point1[1] - point2[1])^2 + (point1[2] - point2[2])^2)

function fix_edge!(g, edge)
    cost = get_prop(g, edge..., :weight)
    set_prop!(g, edge..., :weight, 0.0)
    return cost
end