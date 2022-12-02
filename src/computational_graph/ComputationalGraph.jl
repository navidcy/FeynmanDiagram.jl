module ComputationalGraphs

using AbstractTrees
using Printf, PyCall, DataFrames, Parameters

@enum TwoBodyChannel Alli = 1 PHr PHEr PPr AnyChan
@enum Permutation Di = 1 Ex DiEx

# export TwoBodyChannel, Alli, PHr, PHEr, PPr, AnyChan
# export Permutation, Di, Ex, DiEx

Base.length(r::TwoBodyChannel) = 1
Base.iterate(r::TwoBodyChannel) = (r, nothing)
function Base.iterate(r::TwoBodyChannel, ::Nothing) end

Base.length(r::Permutation) = 1
Base.iterate(r::Permutation) = (r, nothing)
function Base.iterate(r::Permutation, ::Permutation) end

include("common.jl")
include("graph.jl")
# include("tree.jl")
# include("operation.jl")
include("io.jl")
# include("eval.jl")
# include("optimize.jl")

const INL, OUTL, INR, OUTR = 1, 2, 3, 4

export Graph
export ExternalVertex, InternalVertex
export labelreset
export fermionic_annihilation, fermionic_creation, majorana
export bosonic_annihilation, bosonic_creation, real_scalar
# export 𝐺ᶠ, 𝐺ᵇ, 𝐺ᵠ, 𝑊, Green2, Interaction
export QuantumOperator, CompositeOperator
export 𝑓⁻, 𝑓⁺, 𝑓, 𝑏⁻, 𝑏⁺, 𝜙
export feynman_diagram, contractions_to_edgelist, propagator, labelreset
# export Coupling_yukawa, Coupling_phi3, Coupling_phi4, Coupling_phi6

# export addSubDiagram!
# export evalDiagTree!
# export evalDiagTreeKT!
# export Operator, Sum, Prod
# export uidreset
# export toDataFrame, mergeby, plot_tree

end