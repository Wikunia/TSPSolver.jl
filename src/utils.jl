"""
    simple_parse_tsp(filename; verbose = true)

Try to parse the ".tsp" file given by `filename`. Very simple implementation
just to be able to test the optimization; may break on other files. Returns a
list of cities for use in `get_optimal_tour`.
Copied from https://github.com/ericphanson/TravelingSalesmanExact.jl
"""
function simple_parse_tsp(filename; verbose = false)
    cities = Vector{Float64}[]
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
            push!(cities, [x, y])
        end
        # change section type
        if line == "NODE_COORD_SECTION"
            section = :NODE_COORD_SECTION
        end
    end
    return cities
end

function get_edges_cost(edges, cost_mat)
    edges_cost = 0.0
    for edge in edges
        edges_cost += cost_mat[edge.src, edge.dst] 
    end
    return edges_cost
end

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

"""
    euclidean_distance(point1, point2)

The usual Euclidean distance measure.
Copied from https://github.com/ericphanson/TravelingSalesmanExact.jl
"""
euclidean_distance(point1, point2) = sqrt((point1[1] - point2[1])^2 + (point1[2] - point2[2])^2)