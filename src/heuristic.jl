function greedy(points, cost)
    N = length(points)
    visited = Set{Int}(1)
    tour = Int[1]
    last_city = 1
    while length(tour) < N
        last_city = argmin(j->j in visited ? Inf : cost[j, last_city], 1:N)
        push!(visited, last_city)
        push!(tour, last_city)
    end
    return tour, get_tour_cost(tour, cost)
end