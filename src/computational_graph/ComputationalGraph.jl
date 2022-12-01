module ComputationalGraph

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
include("diagram.jl")
# include("tree.jl")
# include("operation.jl")
include("io.jl")
# include("eval.jl")
# include("optimize.jl")


const INL, OUTL, INR, OUTR = 1, 2, 3, 4

export ExternalVertex, InternalVertex, checkVertices
export build_graph, add_edge!, labelreset
export fermionic_annihilation, fermionic_creation, majorana
export bosonic_annihilation, bosonic_creation, real_scalar
# export 𝐺ᶠ, 𝐺ᵇ, 𝐺ᵠ, 𝑊, Green2, Interaction
export QuantumOperator
# export 𝑓, 𝑓dag, γ, 𝑏, 𝑏dag, ϕ
# export CompositeOperator
# export Coupling_yukawa, Coupling_phi3, Coupling_phi4, Coupling_phi6

# export addSubDiagram!
# export evalDiagTree!
# export evalDiagTreeKT!
# export Operator, Sum, Prod
# export uidreset
# export toDataFrame, mergeby, plot_tree

end