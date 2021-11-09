module TSPSolver

using Graphs

include("utils.jl")
include("lb.jl")

function optimize(input_path)
    points = simple_parse_tsp(input_path)
    N = length(points)
    cost = [euclidean_distance(points[i], points[j]) for i = 1:N, j = 1:N]
    tree, lb = get_optimized_1tree(cost)
    return tree, lb
end



end
