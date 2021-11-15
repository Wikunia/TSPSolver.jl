"""
    greedy(points, cost, fixed_edges=Edge[], disallowed_edges=Edge[])

Create a tour which starts at point 1 and goes to the nearest unvisited neighbor in each step.
Return the tour as a list of points and the cost of the tour.
If no tour is possible return `nothing, NaN`
"""
function greedy(points, cost, fixed_edges=zeros(Int, size(cost,1)), disallowed_edges=Dict{Int,Set{Int}}())
    N = length(points)
    visited = Set{Int}()
    # the destination shouldn't be used before by some other edge
    c = 0
    for i in 1:N
        if fixed_edges[i] != 0
            push!(visited, fixed_edges[i])
            c += 1
        end
    end
    if c != length(visited)
        return nothing, NaN
    end
    
    tour = Int[1]
    last_city = 1
    push!(visited, 1)
    while length(tour) < N
        # if already fixed
        if fixed_edges[last_city] != 0
            last_city = fixed_edges[last_city]
        else
            last_city = get_next_city(last_city, visited, cost, disallowed_edges)
            # no edge found
            if last_city == 0
                return nothing, NaN
            end
        end
        push!(visited, last_city)
        push!(tour, last_city)
    end
    # the last edge doesn't match
    if fixed_edges[last_city] != 0 && tour[1] != fixed_edges[last_city]
        return nothing, NaN
    end
    return tour, get_tour_cost(tour, cost)
end

function get_next_city(city, visited, cost, all_disallowed_edges)
    disallowed_edges = get(all_disallowed_edges, city, nothing)
    return get_next_city(city, visited, cost, disallowed_edges)
end

function get_next_city(city, visited, cost, ::Nothing)
    return argmin(j->j in visited ? Inf : cost[j, city], 1:size(cost, 1))
end

function get_next_city(city, visited, cost, disallowed_edges::Set{Int})
    min_val = Inf
    min_idx = 0
    for j in 1:size(cost,1) 
        j in disallowed_edges && continue
        j in visited && continue
        val = cost[city, j]
        if val < min_val
            min_idx = j
            min_val = val
        end
    end
    return min_idx
end
