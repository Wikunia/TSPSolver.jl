"""
    greedy(g)

Create a tour which starts at node 1 and goes to the nearest unvisited neighbor in each step.
Return the tour as a list of nodes and the cost of the tour.
If no tour is possible return `nothing, Inf`. If no tour was found but there isn't a proof that no tour exists 
return `nothing, NaN`.
"""
function greedy(g)
    N = nv(g)
    sorted_neighbors = Vector{Vector{Int}}(undef, N)
    for i in 1:N
        vec_neighbors = collect(neighbors(g,i))
        NN = length(vec_neighbors)
        weights = zeros(NN)
        for j in 1:NN
            weights[j] = get_prop(g, i, vec_neighbors[j], :weight)
        end
        order = sortperm(weights)
        sorted_neighbors[i] = vec_neighbors[order]
        p = findfirst(>(0),weights[order])
        # if three edges are fixed
        if p > 3
            return nothing, Inf
        end
        # if both end points are fixed we can fix them here
        if p == 3
            sorted_neighbors[i] = sorted_neighbors[i][1:2]
        end
    end

    visited = zeros(Bool, N)
    node_next = ones(Int, N)
    tour = zeros(Int, N)
    tour[1] = 1
    visited[1] = true
    cp = 1
    backtrack_c = 0
    while 1 <= cp < N
        # simply give up searching :D
        if backtrack_c == 1000000
            return nothing, NaN
        end
        neighbor = next_neighbor!(g, tour, cp, node_next, visited, sorted_neighbors[tour[cp]])
        if neighbor === nothing
            backtrack_c += 1
            node_next[tour[cp]] = 1
            visited[tour[cp]] = false
            cp -= 1
            if cp == 0
                break
            end
        else 
            visited[neighbor] = true
            cp += 1
            tour[cp] = neighbor
        end
    end
    return tour, get_tour_cost(g, tour)
end

function next_neighbor!(g, tour, cp, node_next, visited, sorted_neighbors)
    for neighbor_id in node_next[tour[cp]]:length(sorted_neighbors)
        node_next[tour[cp]] += 1
        neighbor = sorted_neighbors[neighbor_id]
        visited[neighbor] && continue
        if (cp == length(tour)-1 && !has_edge(g, neighbor, 1))
            continue
        end

        return sorted_neighbors[neighbor_id]
    end
    return nothing
end