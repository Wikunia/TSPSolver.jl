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
    get_edges_cost(g, edges)

Return the sum of the cost of the edges
"""
function get_edges_cost(g::AbstractGraph, edges)
    edges_cost = 0.0
    for edge in edges
        edges_cost += get_prop(g, edge.src, edge.dst, :weight) 
    end
    return edges_cost
end

"""
    get_edges_cost(cost, edges)

Return the sum of the cost of the edges
"""
function get_edges_cost(cost, edges)
    edges_cost = 0.0
    for edge in edges
        edges_cost += cost[edge.src, edge.dst]
    end
    return edges_cost
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

function fix_edge!(root, edge)
    cost = get_prop(root.g, edge..., :weight)
    set_prop!(root.g, edge..., :weight, 0.0)
    root.cost[edge[1], edge[2]] = 0.0
    root.cost[edge[2], edge[1]] = 0.0
    return cost
end

function disallow_edge!(root, edge)
    rem_edge!(root.g, edge...)
    root.cost[edge[1], edge[2]] = Inf
    root.cost[edge[2], edge[1]] = Inf
end

function set_cost!(root, edge, cost)
    set_prop!(root.g, edge..., :weight, cost)
    root.cost[edge[1], edge[2]] = cost
    root.cost[edge[2], edge[1]] = cost
end

"""
    edges_to_tour(n, edges::Vector{<:AbstractEdge})

Return an edge based on a list of edges.
"""
function edges_to_tour(n, edges::Vector{<:AbstractEdge})
    next_vertex = zeros(Int, (2,n))
    for edge in edges
        if next_vertex[1,edge.src] == 0
            next_vertex[1,edge.src] = edge.dst
        else 
            next_vertex[2,edge.src] = edge.dst
        end
        if next_vertex[1,edge.dst] == 0
            next_vertex[1,edge.dst] = edge.src
        else 
            next_vertex[2,edge.dst] = edge.src
        end
    end
    tour = zeros(Int, n)
    tour[1] = 1
    for i in 2:n
        tour[i] = get_next_vertex(tour, i, next_vertex)
    end
    return tour
end

"""
    get_next_vertex(tour, i, next_vertex)

Return the next vertex given a tour the next position and a matrix which maps each vertex to its two possible neighbors.
"""
function get_next_vertex(tour, i, next_vertex)
    if i == 2
        return next_vertex[1, tour[i-1]]
    end
    prev_vertex = tour[i-2]
    if next_vertex[1, tour[i-1]] == prev_vertex
        return next_vertex[2, tour[i-1]]
    end
    return next_vertex[1, tour[i-1]]
end