module TSPSolver

using Bonobo
using Graphs
using MetaGraphs
using DataStructures

include("utils.jl")
include("lb.jl")
include("heuristic.jl")

struct LONGEST_EDGE <: Bonobo.AbstractBranchStrategy end

mutable struct Node <: AbstractNode
    std :: BnBNodeInfo
    tour :: Union{Nothing, Vector{Int}}
    mst :: Union{Nothing, Vector{Edge{Int}}}
    fixed_edges :: Vector{Tuple{Int,Int}}
    disallowed_edges :: Vector{Tuple{Int,Int}}
end

struct Root
    g::MetaGraph
    cost::Matrix{Float64}
    function Root(g::MetaGraph)
        cost = zeros((nv(g), nv(g)))
        for i in 1:nv(g)
            for j in i+1:nv(g)
                weight = get_prop(g, i, j, :weight)
                cost[i,j] = weight
                cost[j,i] = weight
            end
        end
        new(g,cost)
    end
end

function Bonobo.get_branching_indices(root::Root)
    return 1:1
end

function Bonobo.evaluate_node!(tree::BnBTree{Node, Root}, node::Node)
    root = deepcopy(tree.root)
    extra_cost = 0.0
    for fixed_edge in node.fixed_edges
        extra_cost += fix_edge!(root, fixed_edge)
    end
    for disallowed_edge in node.disallowed_edges
        disallow_edge!(root, disallowed_edge)
    end
    
    # @show node.fixed_edges
    # @show node.disallowed_edges

    mst, lb = get_optimized_1tree(root.cost; runs=50)
    # @time mst, lb = get_1tree(weights(g))
    tour, ub = greedy(root.g)
    if tour !== nothing
        tour, ub = two_opt(tour, ub, root.cost)
    end
    lb += extra_cost 
    ub += extra_cost
    node.mst = mst
    node.tour = tour
    # no tour can exist
    if isinf(ub)
        return NaN, NaN
    end
   # @show lb
   # @show ub
   # @show tree.incumbent
   # @show tree.lb
   # @show length(tree.nodes)
   # println("======================================================")
    return lb, ub
end

function Bonobo.get_relaxed_values(tree::BnBTree{Node, Root}, node::Node)
    return node.tour
end

function Bonobo.get_branching_variable(tree::BnBTree{Node, Root}, ::LONGEST_EDGE, node::Node)
    longest_len = 0.0
    longest_edge = -1
    tour_edges = Set{Tuple{Int, Int}}()
    longest_is_tour_edge = true
    if node.tour !== nothing 
        for i in 1:length(node.tour)
            push!(tour_edges, extrema((node.tour[i], node.tour[mod1(i+1, end)])))
        end
    end
    for edge in node.mst
        edge_tpl = extrema((edge.src, edge.dst))
        if !(edge_tpl in node.fixed_edges) && !(edge_tpl in node.disallowed_edges)
            len = get_prop(tree.root.g, edge_tpl..., :weight)
            is_tour_edge = edge_tpl in tour_edges
            if (len > longest_len && !is_tour_edge) || longest_is_tour_edge
                longest_edge = edge
                longest_len = len
                longest_is_tour_edge = is_tour_edge
            end
        end
    end
    return longest_edge
end

function Bonobo.get_branching_nodes_info(tree::BnBTree{Node, Root}, node::Node, branching_edge::Edge)
    nodes_info = NamedTuple[]
    new_fixed_edges = deepcopy(node.fixed_edges)
    push!(new_fixed_edges, extrema((branching_edge.src, branching_edge.dst)))
    push!(nodes_info, (
        tour = nothing,
        mst = nothing, 
        fixed_edges = new_fixed_edges,
        disallowed_edges = deepcopy(node.disallowed_edges),
    ))

    new_disallowed_edges = deepcopy(node.disallowed_edges)
    push!(new_disallowed_edges, extrema((branching_edge.src, branching_edge.dst)))
    push!(nodes_info, (
        tour = nothing,
        mst = nothing, 
        fixed_edges = deepcopy(node.fixed_edges),
        disallowed_edges = new_disallowed_edges,
    ))
    return nodes_info
end

function optimize(input_path)
    g = simple_parse_tsp(input_path)
    
    bnb_model = Bonobo.initialize(
        traverse_strategy = Bonobo.BFS(),
        branch_strategy = LONGEST_EDGE(),
        Node = Node,
        root = Root(g),
        sense = :Min,
        Value = Vector{Int},
        log_table = false
    )

    Bonobo.set_root!(bnb_model, (
        tour = nothing,
        mst = nothing,
        fixed_edges = Vector{Tuple{Int,Int}}(),
        disallowed_edges = Vector{Tuple{Int,Int}}()
    ))

    Bonobo.optimize!(bnb_model)

    return bnb_model
end



end
