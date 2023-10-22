"""
    mutable struct Graph{F,W}
    
    A representation of a computational graph, e.g., an expression tree, with type stable node data.

# Members:
- `id::Int`  the unique hash id to identify the diagram
- `name::Symbol`  name of the diagram
- `orders::Vector{Int}`  orders associated with the graph, e.g., derivative orders
- `subgraphs::Vector{Graph{F,W}}`  vector of sub-diagrams 
- `subgraph_factors::Vector{F}`  scalar multiplicative factors associated with each subgraph. Note that the subgraph factors may be manipulated algebraically. To associate a fixed multiplicative factor with this graph which carries some semantic meaning, use the `factor` argument instead.
- `operator::DataType`  node operation. Addition and multiplication are natively supported via operators Sum and Prod, respectively. Should be a concrete subtype of `AbstractOperator`.
- `factor::F`  total scalar multiplicative factor for the diagram
- `weight::W`  the weight of this node

# Example:
```julia-repl
julia> g1 = Graph([])
1=0.0

julia> g2 = Graph([]; factor=2)
2⋅2.0=0.0

julia> g = Graph([g1, g2]; operator=ComputationalGraphs.Sum())
3=0.0=⨁ (1,2)
```
"""
mutable struct Graph{F,W} <: AbstractGraph # Graph
    id::Int
    name::String # "" by default
    orders::Vector{Int}

    subgraphs::Vector{Graph{F,W}}
    subgraph_factors::Vector{F}

    operator::DataType
    factor::F
    weight::W

    """
        function Graph(subgraphs::AbstractVector; name="", operator::AbstractOperator=Sum(),
            ftype=_dtype.factor, wtype=_dtype.weight, factor=one(ftype), weight=zero(wtype))
        
        Create a Graph struct from a set of subgraphs with the specified node data and operation.

    # Arguments:
    - `subgraphs`  vector of sub-diagrams 
    - `subgraph_factors`  scalar multiplicative factors associated with each subgraph. Note that the subgraph factors may be manipulated algebraically. To associate a fixed multiplicative factor with this graph which carries some semantic meaning, use the `factor` argument instead.
    - `name`  name of the diagram
    - `orders`  orders associated with the graph, e.g., derivative orders
    - `operator`  node operation, i.e., Sum, Prod, or a user-defined operator `Op <: AbstractOperator`
    - `ftype`  typeof(factor)
    - `wtype`  typeof(weight)
    - `factor`  fixed scalar multiplicative factor for this diagram (e.g., a permutation sign)
    - `weight`  the weight of this node
    """
    function Graph(subgraphs::AbstractVector; subgraph_factors=one.(eachindex(subgraphs)), name="", operator::AbstractOperator=Sum(),
        orders=zeros(Int, 16), ftype=_dtype.factor, wtype=_dtype.weight, factor=one(ftype), weight=zero(wtype)
    )
        return new{ftype,wtype}(uid(), name, orders, subgraphs, subgraph_factors, typeof(operator), factor, weight)
    end
end

### AbstractGraph interface for Graph ###

# Getters
id(g::Graph) = g.id
name(g::Graph) = g.name
orders(g::Graph) = g.orders
operator(g::Graph) = g.operator
factor(g::Graph) = g.factor
weight(g::Graph) = g.weight
subgraph(g::Graph, i=1) = g.subgraphs[i]
subgraphs(g::Graph) = g.subgraphs
subgraphs(g::Graph, indices::AbstractVector{Int}) = g.subgraphs[indices]
subgraph_factor(g::Graph, i=1) = g.subgraph_factors[i]
subgraph_factors(g::Graph) = g.subgraph_factors
subgraph_factors(g::Graph, indices::AbstractVector{Int}) = g.subgraph_factors[indices]

# Setters
set_name!(g::Graph, name::AbstractString) = (g.name = name)
set_subgraph!(g::Graph, subgraph::Graph, i=1) = (g.subgraphs[i] = subgraph)
set_subgraphs!(g::Graph, subgraphs::Vector{Graph}) = (g.subgraphs = subgraphs)
set_subgraphs!(g::Graph, subgraphs::Vector{Graph}, indices::AbstractVector{Int}) = (g.subgraphs[indices] = subgraphs)
set_subgraph_factor!(g::Graph, subgraph_factor::Graph, i=1) = (g.subgraph_factors[i] = subgraph_factor)
set_subgraph_factors!(g::Graph, subgraph_factors::AbstractVector) = (g.subgraph_factors = subgraph_factors)
set_subgraph_factors!(g::Graph, subgraph_factors::AbstractVector, indices::AbstractVector{Int}) = (g.subgraph_factors[indices] = subgraph_factors)

###############################

"""
    function Base.:*(g1::Graph{F,W}, c2) where {F,W}

    Returns a graph representing the scalar multiplication `g1*c2`.

# Arguments:
- `g1`  computational graph
- `c2`  scalar multiple
"""
function Base.:*(g1::Graph{F,W}, c2) where {F,W}
    g = Graph([g1,]; subgraph_factors=[F(c2),], operator=Prod(), orders=orders(g1), ftype=F, wtype=W)
    # Merge multiplicative link
    if g1.operator == Prod && onechild(g1)
        g.subgraph_factors[1] *= g1.subgraph_factors[1]
        g.subgraphs = g1.subgraphs
    end
    return g
end

"""
    function Base.:*(c1, g2::Graph{F,W}) where {F,W}

    Returns a graph representing the scalar multiplication `c1*g2`.

# Arguments:
- `c1`  scalar multiple
- `g2`  computational graph
"""
function Base.:*(c1, g2::Graph{F,W}) where {F,W}
    g = Graph([g2,]; subgraph_factors=[F(c1),], operator=Prod(), orders=orders(g2), ftype=F, wtype=W)
    # Merge multiplicative link
    if g2.operator == Prod && onechild(g2)
        g.subgraph_factors[1] *= g2.subgraph_factors[1]
        g.subgraphs = g2.subgraphs
    end
    return g
end

"""
    function linear_combination(g1::Graph{F,W}, g2::Graph{F,W}, c1, c2) where {F,W}

    Returns a graph representing the linear combination `c1*g1 + c2*g2`.
    Graphs `g1` and `g2` must have the same orders.

# Arguments:
- `g1`  first computational graph
- `g2`  second computational graph
- `c1`  first scalar multiple
- `c2`  second scalar multiple
"""
function linear_combination(g1::Graph{F,W}, g2::Graph{F,W}, c1, c2) where {F,W}
    @assert orders(g1) == orders(g2) "g1 and g2 have different orders."
    g = Graph([g1, g2]; subgraph_factors=[F(c1), F(c2)], operator=Sum(), orders=orders(g1), ftype=F, wtype=W)
    # Convert multiplicative links to in-place form
    if g1.operator == Prod && onechild(g1)
        g.subgraph_factors[1] *= g1.subgraph_factors[1]
        g.subgraphs[1] = g1.subgraphs[1]
    end
    if g2.operator == Prod && onechild(g2)
        g.subgraph_factors[2] *= g2.subgraph_factors[1]
        g.subgraphs[2] = g2.subgraphs[1]
    end
    return g
end

"""
    function linear_combination(graphs::Vector{Graph{F,W}}, constants::Vector{C}) where {F,W}

    Given a vector 𝐠 of graphs each with the same type and external/internal
    vertices and an equally-sized vector 𝐜 of constants, returns a new
    graph representing the linear combination (𝐜 ⋅ 𝐠). 
    All input graphs must have the same orders.

# Arguments:
- `graphs`  vector of computational graphs
- `constants`  vector of scalar multiples
"""
function linear_combination(graphs::Vector{Graph{F,W}}, constants::AbstractVector) where {F,W}
    @assert alleq(orders.(graphs)) "Graphs do not all have the same order."
    # parameters = union(getproperty.(graphs, :parameters))
    g1 = graphs[1]
    g = Graph(graphs; subgraph_factors=F.(constants), operator=Sum(), orders=orders(g1), ftype=F, wtype=W)
    # Convert multiplicative links to in-place form
    for (i, sub_g) in enumerate(g.subgraphs)
        if sub_g.operator == Prod && onechild(sub_g)
            g.subgraph_factors[i] *= sub_g.subgraph_factors[1]
            g.subgraphs[i] = sub_g.subgraphs[1]
        end
    end
    return g
end

"""
    function Base.:+(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}

    Returns a graph `g1 + g2` representing the addition of `g2` with `g1`.
    Graphs `g1` and `g2` must have the same orders.

# Arguments:
- `g1`  first computational graph
- `g2`  second computational graph
"""
function Base.:+(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}
    return linear_combination(g1, g2, F(1), F(1))
end

"""
    function Base.:-(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}

    Returns a graph `g1 - g2` representing the subtraction of `g2` from `g1`.
    Graphs `g1` and `g2` must have the same orders.

# Arguments:
- `g1`  first computational graph
- `g2`  second computational graph
"""
function Base.:-(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}
    return linear_combination(g1, g2, F(1), F(-1))
end

"""
    function Base.:*(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}

    Returns a graph `g1 * g2` representing the graph product between `g1` and `g2`.

# Arguments:
- `g1`  first computational graph
- `g2`  second computational graph
"""
function Base.:*(g1::Graph{F,W}, g2::Graph{F,W}) where {F,W}
    @todo
end
