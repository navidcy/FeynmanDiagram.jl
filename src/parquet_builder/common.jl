import ..Filter
import ..Wirreducible  #remove all polarization subdiagrams
import ..Girreducible  #remove all self-energy inseration
import ..NoHatree
import ..NoFock
import ..NoBubble  # true to remove all bubble subdiagram
import ..Proper  #ver4, ver3, and polarization diagrams may require to be irreducible along the transfer momentum/frequency

import ..DiagramType
import ..GreenDiag
import ..SigmaDiag
import ..PolarDiag
import ..Ver3Diag
import ..Ver4Diag

import ..Composite
import ..ChargeCharge
import ..SpinSpin
import ..UpUp
import ..UpDown
import ..Response

import ..Instant
import ..Dynamic
import ..D_Instant
import ..D_Dynamic
import ..AnalyticProperty

import ..symbol
import ..short

import ..Interaction
import ..GenericPara
import ..innerTauNum

import ..Diagram

import ..DiagramId
import ..Ver4Id
import ..Ver3Id
import ..GreenId
import ..SigmaId
import ..PolarId
import ..InteractionId

import ..TwoBodyChannel
import ..Alli
import ..PHr
import ..PHEr
import ..PPr
import ..AnyChan

import ..Permutation
import ..Di
import ..Ex
import ..DiEx

import ..uidreset
import ..toDataFrame
import ..mergeby

"""
    struct ParquetBlocks

    The channels of the left and right sub-vertex4 of a bubble diagram in the parquet equation

#Members
- `phi`   : channels of left sub-vertex for the particle-hole and particle-hole-exchange bubbles
- `ppi`   : channels of left sub-vertex for the particle-particle bubble
- `Γ4`   : channels of right sub-vertex of all channels
"""
struct ParquetBlocks
    phi::Vector{TwoBodyChannel}
    ppi::Vector{TwoBodyChannel}
    Γ4::Vector{TwoBodyChannel}
    function ParquetBlocks(; phi = [Alli, PHEr, PPr], ppi = [Alli, PHr, PHEr], Γ4 = union(phi, ppi))
        return new(phi, ppi, Γ4)
    end
end

function Base.isequal(a::ParquetBlocks, b::ParquetBlocks)
    if issetequal(a.phi, b.phi) && issetequal(a.ppi, b.ppi) && issetequal(a.Γ4, b.Γ4)
        return true
    else
        return false
    end
end
Base.:(==)(a::ParquetBlocks, b::ParquetBlocks) = Base.isequal(a, b)

function orderedPartition(_total, n, lowerbound = 1)
    @assert lowerbound >= 0
    total = _total - n * (lowerbound - 1)
    @assert total >= n
    unorderedPartition = collect(partitions(total, n))
    #e.g., loopNum =5, n =2 ==> unordered = [[4, 1], [3, 2]]
    orderedPartition = Vector{Vector{Int}}([])
    for p in unorderedPartition
        p = p .+ (lowerbound - 1)
        @assert sum(p) == _total
        for i in p
            @assert i >= lowerbound
        end
        append!(orderedPartition, Set(permutations(p)))
    end
    #e.g., loopNum =5, n =2 ==> ordered = [[4, 1], [1, 4], [3, 2], [2, 3]]
    return orderedPartition
end

function findFirstLoopIdx(partition, firstidx::Int)
    ## example: firstidx = 1
    # partition = [1, 1, 2, 1], then the loop partition = [1][2][34][5], thus firstTauIdx = [1, 2, 3, 5]
    # partition = [1, 0, 2, 0], then the loop partition = [1][][23][], thus firstTauIdx = [1, 2, 2, 4]
    # @assert length(partition) == length(isG)
    accumulated = accumulate(+, partition; init = firstidx) #  idx[i] = firstidx + p[1]+p[2]+...+p[i]
    firstLoopIdx = [firstidx,]
    append!(firstLoopIdx, accumulated[1:end-1])
    maxLoopIdx = accumulated[end] - 1
    return firstLoopIdx, maxLoopIdx
end

function findFirstTauIdx(partition::Vector{Int}, diagType::Vector{DiagramType}, firstidx::Int, _tauNum::Int)
    ## example: diagType =[Vertex4, GreenDiagram, Vertex4, GreenDiagram], firstidx = 1
    # n-loop G has n*_tauNum DOF, while n-loop ver4 has (n+1)*_tauNum DOF
    # partition = [1, 1, 2, 1], then the tau partition = [12][3][456][7], thus firstTauIdx = [1, 3, 4, 7]
    # partition = [1, 0, 2, 0], then the tau partition = [12][][345][], thus firstTauIdx = [1, 3, 3, 6]
    @assert length(partition) == length(diagType)
    @assert _tauNum >= 0
    taupartition = [innerTauNum(diagType[i], p, _tauNum) for (i, p) in enumerate(partition)]
    accumulated = accumulate(+, taupartition; init = firstidx) #  idx[i] = firstidx + p[1]+p[2]+...+p[i]
    firstTauidx = [firstidx,]
    append!(firstTauidx, accumulated[1:end-1])
    maxTauIdx = accumulated[end] - 1
    return firstTauidx, maxTauIdx
end

# function newDiagTree(para, name::Symbol = :none)
#     weightType = para.weightType
#     Kpool = DiagTree.LoopPool(:K, para.loopDim, para.totalLoopNum, Float64)
#     # nodeParaType = Vector{Int}
#     nodeParaType = Any
#     propagatorPool = []
#     push!(propagatorPool, DiagTree.propagatorPool(:Gpool, weightType))
#     for interaction in para.interaction
#         response = interaction.response
#         for type in interaction.type
#             push!(propagatorPool, DiagTree.propagatorPool(symbol(response, type, "pool"), weightType))
#         end
#     end
#     return DiagTree.Diagrams(Kpool, Tuple(propagatorPool), weightType, nodeParaType = nodeParaType, name = name)
# end

function allsame(df, name::Symbol)
    @assert all(x -> x == df[1, name], df[!, name]) "Not all rows of the $name field are the same.\n$df"
end
function allsame(df, names::Vector{Symbol})
    for name in names
        allsame(df, name)
    end
end
function allsametype(df, name::Symbol)
    @assert all(x -> typeof(x) == typeof(df[1, name]), df[!, name]) "Not all rows of the $name field are the same type.\n$df"
end
function allsametype(df, names::Vector{Symbol})
    for name in names
        allsametype(df, name)
    end
end


# struct ParameterizedComponent
#     component::Component
#     para::Any
# end
# const ComponentExtT = Tuple{Component,Tuple{Int,Int}}

# function connectComponentsbyGreen(diag, originalPara::GenericPara, name, loopBasis, extT::Tuple{Int,Int}, loopNumofG::Vector{Int},
#     diagType::Vector{DiagramType}, componentsVector::Vector{Vector{ComponentExt}}, factor = 1.0; para = extT)
#     #each component.para must be (tin, tout) or [tin, tout]
#     @assert length(loopNumofG) == (length(componentsVector) + 1)

#     for loop in loopNumofG
#         if isValidG(para.filter, loop) == false
#             @error("Some of the Green's function doesn't exist in the loopNum list $loopNumofG")
#         end
#     end
#     for c in componentsVector
#         @assert isempty(c) "Some of the components are empty!$componentsVector"
#     end

#     nodes = []
#     for configuration in Iterators.product(Tuple(componentsVector)...)
#         components = [ct[1] for ct in configuration]
#         _extT = [ct[2] for ct in configuration]

#         ########## prepare G extT ##################
#         GextT = [(extT[1], _extT[1][1]),]
#         for i in 1:length(_extT)-1
#             push!(GextT, (_extT[i][2], _extT[i+1][1]))
#         end
#         push!(GextT, (_extT[end][2], extT[2]))

#         for tpair in GextT
#             push!(components, DiagTree.addpropagator!(diag, :Gpool, 0, :G; site = tpair, loop = loopBasis))
#         end
#         node = DiagTree.addnode!(diag, MUL, name, components, factor; para = para)
#         @assert node.index > 0
#         push!(nodes, node)
#     end
#     n = DiagTree.addnode!(diag, ADD, name, nodes, factor; para = para)
#     @assert n.index > 0
#     return n
# end