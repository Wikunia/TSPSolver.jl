module TSPSolver

using Bonobo
using Graphs
using MetaGraphs
using DataStructures

include("utils.jl")
include("lb.jl")
include("heuristic.jl")

mutable struct Node <: AbstractNode
    std :: BnBNodeInfo
    tour :: Union{Nothing, Vector{Int}}
    mst :: Union{Nothing, Vector{Edge{Int}}}
    fixed_edges :: Vector{Tuple{Int,Int}}
    disallowed_edges :: Vector{Tuple{Int,Int}}
    status :: Symbol
end

struct Root
    g::MetaGraph
end

function Bonobo.get_branching_indices(root::Root)
    return 1:1
end

function Bonobo.evaluate_node!(tree::BnBTree{Node, Root}, node::Node)
    g = deepcopy(tree.root.g)
    extra_cost = 0.0
    for fixed_edge in node.fixed_edges
        extra_cost += get_prop(g, fixed_edge..., :weight)
        fix_edge!(g, fixed_edge)
    end
    for disallowed_edge in node.disallowed_edges
        rem_edge!(g, disallowed_edge...)
    end

    #@show node.fixed_edges
    #@show node.disallowed_edges

    @time mst, lb = get_optimized_1tree(g; runs=20)
    @time tour, ub = greedy(g)
    println("=============")
    lb += extra_cost 
    ub += extra_cost
    node.mst = mst
    node.tour = tour
    # no tour can exist
    if isinf(ub)
        return NaN, NaN
    end
    #@show lb
    #@show ub
    #@show tree.incumbent
    #@show tree.lb
    #@show length(tree.nodes)
    #println("======================================================")
    return lb, ub
end

function Bonobo.get_relaxed_values(tree::BnBTree{Node, Root}, node::Node)
    return node.tour
end

function Bonobo.get_branching_variable(tree::BnBTree{Node, Root}, ::Bonobo.FIRST, node::Node)
    longest_len = 0.0
    longest_edge = -1
    for edge in node.mst
        edge_tpl = (edge.src, edge.dst)
        if !(edge_tpl in node.fixed_edges) && !(edge_tpl in node.disallowed_edges)
            len = get_prop(tree.root.g, edge_tpl..., :weight)
            if len > longest_len
                longest_edge = edge
                longest_len = len
            end
        end
    end
    return longest_edge
end

function Bonobo.get_branching_nodes_info(tree::BnBTree{Node, Root}, node::Node, branching_edge::Edge)
    nodes_info = NamedTuple[]
    new_fixed_edges = deepcopy(node.fixed_edges)
    push!(new_fixed_edges, (branching_edge.src, branching_edge.dst))
    push!(nodes_info, (
        tour = nothing,
        mst = nothing, 
        fixed_edges = new_fixed_edges,
        disallowed_edges = deepcopy(node.disallowed_edges),
        status = :NotCalledYet
    ))

    new_disallowed_edges = deepcopy(node.disallowed_edges)
    push!(new_disallowed_edges, (branching_edge.src, branching_edge.dst))
    push!(nodes_info, (
        tour = nothing,
        mst = nothing, 
        fixed_edges = deepcopy(node.fixed_edges),
        disallowed_edges = new_disallowed_edges,
        status = :NotCalledYet
    ))
    return nodes_info
end

function optimize(input_path)
    g = simple_parse_tsp(input_path)
    
    bnb_model = Bonobo.initialize(
        traverse_strategy = Bonobo.BFS,
        branch_strategy = Bonobo.FIRST,
        Node = Node,
        root = Root(g),
        sense = :Min,
        Value = Vector{Int}
    )

    Bonobo.set_root!(bnb_model, (
        tour = nothing,
        mst = nothing,
        fixed_edges = Vector{Tuple{Int,Int}}(),
        disallowed_edges = Vector{Tuple{Int,Int}}(),
        status = :NotCalledYet
    ))

    Bonobo.optimize!(bnb_model)

    return bnb_model
end



end
