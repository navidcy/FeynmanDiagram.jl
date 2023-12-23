module ComputationalGraphs

using AbstractTrees
using StaticArrays
using Printf, PyCall, DataFrames
#using ..Taylor
macro todo()
    return :(error("Not yet implemented!"))
end

import ..QuantumOperators: QuantumOperator, OperatorProduct, 𝑓⁻, 𝑓⁺, 𝑓, 𝑏⁻, 𝑏⁺, 𝜙, iscreation, isannihilation, isfermionic, parity, normal_order, correlator_order
# import ..QuantumOperators: 𝑓⁻ₑ, 𝑓⁺ₑ, 𝑓ₑ, 𝑏⁻ₑ, 𝑏⁺ₑ, 𝜙ₑ

include("common.jl")
export labelreset
export _dtype
export set_datatype

include("abstractgraph.jl")
export AbstractGraph, AbstractOperator
export unary_istrivial, isassociative, isequiv

include("graph.jl")
include("feynmangraph.jl")
include("conversions.jl")

export Graph, FeynmanGraph, FeynmanProperties
# export DiagramType

export isequiv, drop_topology, is_external, is_internal, diagram_type, orders, vertices, topology
export external_legs, external_indices, external_operators, external_labels
export multi_product, linear_combination, feynman_diagram, propagator, interaction, external_vertex

# export Prod, Sum
# export DiagramType, Interaction, ExternalVertex, Propagator, SelfEnergy, VertexDiag, GreenDiag, GenericDiag
# export standardize_order!
# export 𝐺ᶠ, 𝐺ᵇ, 𝐺ᵠ, 𝑊, Green2, Interaction


include("tree_properties.jl")
export haschildren, onechild, isleaf, isbranch, ischain, isfactorless, has_zero_subfactors, eldest, count_operation

include("operation.jl")
include("io.jl")
# plot_tree

include("eval.jl")
export eval!

include("transform.jl")
export relabel!, standardize_labels!, replace_subgraph!, merge_linear_combination!, merge_multi_product!, merge_chains!, flatten_chains!
export relabel, standardize_labels, replace_subgraph, merge_linear_combination, merge_multi_product, merge_chains, flatten_chains
export open_parenthesis, flatten_prod!, flatten_prod
include("optimize.jl")
export optimize!, optimize

end
