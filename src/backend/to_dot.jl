function to_dotstatic(operator::Type, id::Int, factor, subgraphs::AbstractVector{<:AbstractGraph}, subgraph_factors::AbstractVector)
    error(
        "Static representation for computational graph nodes with operator $(operator) not yet implemented! " 
    )
end

function to_dotstatic(::Type{ComputationalGraphs.Sum}, id::Int, factor::F,subgraphs::Vector{Graph{F,W}}, subgraph_factors::Vector{F}) where {F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node = opr_name * "[shape=box, label = \"Add\", style=filled, fillcolor=cyan,]\n"
    node_temp *= opr_node
    for (gix,(g, gfactor)) in enumerate(zip(subgraphs, subgraph_factors))
        if gfactor!= 1
            factor_str = "factor$(g.id)_$(id)_$gix[label=$(gfactor), style=filled, fillcolor=lavender]\n" 
            subg_str = "g$(g.id)_$(id)_$gix[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
            node_temp *= factor_str * subg_str
            arrow_temp *= "factor$(g.id)_$(id)_$gix->g$(g.id)_$(id)_$gix[arrowhead=vee,]\ng$(g.id)->g$(g.id)_$(id)_$gix[arrowhead=vee,]\n"
            arrow_temp *= "g$(g.id)_$(id)_$gix->$opr_name[arrowhead=vee,]\n"
        else
            arrow_temp *= "g$(g.id)->$opr_name[arrowhead=vee,]\n"
        end
    end
    return node_temp,arrow_temp
end

function to_dotstatic(::Type{ComputationalGraphs.Prod}, id::Int, factor::F, subgraphs::Vector{Graph{F,W}}, subgraph_factors::Vector{F}) where {F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node  = opr_name * "[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n" 
    node_temp *= opr_node
    if length(subgraphs) == 1
        if subgraph_factors[1] ==1
            arrow_temp *= "g$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
        else
            factor_str = "factor$(subgraphs[1].id)_$(id)[label=$(subgraph_factors[1]), style=filled, fillcolor=lavender]\n" 
            node_temp *= factor_str
            arrow_temp *= "factor$(subgraphs[1].id)_$(id)->$opr_name[arrowhead=vee,]\ng$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
        end
    else
        for (gix,(g, gfactor)) in enumerate(zip(subgraphs, subgraph_factors))
            if gfactor!= 1
               factor_str = "factor$(g.id)_$(id)_$gix[label=$(gfactor), style=filled, fillcolor=lavender]\n" 
                subg_str = "g$(g.id)_$(id)_$gix[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
                node_temp *= factor_str * subg_str
                arrow_temp *= "factor$(g.id)_$(id)_$gix->g$(g.id)_$(id)_$gix[arrowhead=vee,]\ng$(g.id)->g$(g.id)_$(id)_$gix[arrowhead=vee,]\n"
                arrow_temp *= "g$(g.id)_$(id)_$gix->$opr_name[arrowhead=vee,]\n"
            else
                arrow_temp *= "g$(g.id)->$opr_name[arrowhead=vee,]\n"
            end
        end
    end
    return node_temp,arrow_temp
end

function to_dotstatic(::Type{ComputationalGraphs.Power{N}}, id::Int, factor::F, subgraphs::Vector{Graph{F,W}}, subgraph_factors::Vector{F}) where {N,F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node  = opr_name * "[shape=box, label = \"Pow\", style=filled, fillcolor=darkolivegreen,]\n" 
    order_node = "order$(id)[label=$N, style=filled, fillcolor=lavender]\n"
    node_temp *= opr_node * order_node
    arrow_temp*= "order$(id)->$opr_name[arrowhead=vee,]\n"
    if subgraph_factors[1] != 1
        factor_str = "factor$(subgraphs[1].id)_$(id)[label=$(subgraph_factors[1]), style=filled, fillcolor=lavender]\n" 
        subg_str = "g$(subgraphs[1].id)_$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        node_temp *= factor_str * subg_str
        arrow_temp *= "factor$(subgraphs[1].id)_$(id)->g$(subgraphs[1].id)_$(id)[arrowhead=vee,]\ng$(subgraphs[1].id)->g$(subgraphs[1].id)_$(id)[arrowhead=vee,]\n"
        arrow_temp *= "g$(subgraphs[1].id)_$(id)->$opr_name[arrowhead=vee,]\n"
    else
        arrow_temp *= "g$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
    end
    return node_temp, arrow_temp
end

function to_dotstatic(::Type{ComputationalGraphs.Sum},  id::Int, factor::F,subgraphs::Vector{FeynmanGraph{F,W}}, subgraph_factors::Vector{F}) where {F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node = opr_name * "[shape=box, label = \"Add\", style=filled, fillcolor=cyan,]\n"
    node_temp *= opr_node
    for (gix, (g, gfactor)) in enumerate(zip(subgraphs, subgraph_factors))
        if gfactor != 1
            factor_str = "factor$(g.id)_$(id)_$gix[label=$(gfactor), style=filled, fillcolor=lavender]\n"
            subg_str = "g$(g.id)_$(id)_$gix[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
            node_temp *= factor_str * subg_str
            arrow_temp *= "factor$(g.id)_$(id)_$gix->g$(g.id)_$(id)_$gix[arrowhead=vee,]\ng$(g.id)->g$(g.id)_$(id)_$gix[arrowhead=vee,]\n"
            arrow_temp *= "g$(g.id)_$(id)_$gix->$opr_name[arrowhead=vee,]\n"
        else
            arrow_temp *= "g$(g.id)->$opr_name[arrowhead=vee,]\n"
        end
    end
    return node_temp,arrow_temp
end

function to_dotstatic(::Type{ComputationalGraphs.Prod}, id::Int, factor::F, subgraphs::Vector{FeynmanGraph{F,W}}, subgraph_factors::Vector{F}) where {F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node  = opr_name * "[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n" 
    node_temp *= opr_node
    if length(subgraphs) == 1
        if subgraph_factors[1] ==1
            arrow_temp *= "g$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
        else
            factor_str = "factor$(subgraphs[1].id)_$(id)[label=$(subgraph_factors[1]), style=filled, fillcolor=lavender]\n" 
            node_temp *= factor_str
            arrow_temp *= "factor$(subgraphs[1].id)_$(id)->$opr_name[arrowhead=vee,]\ng$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
        end
    else
        for (gix, (g, gfactor)) in enumerate(zip(subgraphs, subgraph_factors))
            if gfactor != 1
                factor_str = "factor$(g.id)_$(id)_$gix[label=$(gfactor), style=filled, fillcolor=lavender]\n"
                subg_str = "g$(g.id)_$(id)_$gix[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
                node_temp *= factor_str * subg_str
                arrow_temp *= "factor$(g.id)_$(id)_$gix->g$(g.id)_$(id)_$gix[arrowhead=vee,]\ng$(g.id)->g$(g.id)_$(id)_$gix[arrowhead=vee,]\n"
                arrow_temp *= "g$(g.id)_$(id)_$gix->$opr_name[arrowhead=vee,]\n"
            else
                arrow_temp *= "g$(g.id)->$opr_name[arrowhead=vee,]\n"
            end
        end
    end
    return node_temp,arrow_temp
end

function to_dotstatic(::Type{ComputationalGraphs.Power{N}}, id::Int, factor::F, subgraphs::Vector{FeynmanGraph{F,W}}, subgraph_factors::Vector{F}) where {N,F,W}
    node_temp = ""
    arrow_temp = ""
    if factor != 1
        opr_fac = "factor$(id)[label=$(factor), style=filled, fillcolor=lavender]\n"
        opr_name =  "g$(id)_t"
        node_str  = "g$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        arrow_temp*= "factor$(id)->g$(id)[arrowhead=vee,]\ng$(id)_t->g$(id)[arrowhead=vee,]\n"
        node_temp *= opr_fac * node_str
    else
        opr_name = "g$id"
    end
    opr_node  = opr_name * "[shape=box, label = \"Pow\", style=filled, fillcolor=darkolivegreen,]\n" 
    order_node = "order$(id)[label=$N, style=filled, fillcolor=lavender]\n"
    node_temp *= opr_node * order_node
    arrow_temp*= "order$(id)->$opr_name[arrowhead=vee,]\n"
    if subgraph_factors[1] != 1
        factor_str = "factor$(subgraphs[1].id)_$(id)[label=$(subgraph_factors[1]), style=filled, fillcolor=lavender]\n" 
        subg_str = "g$(subgraphs[1].id)_$(id)[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
        node_temp *= factor_str * subg_str
        arrow_temp *= "factor$(subgraphs[1].id)_$(id)->g$(subgraphs[1].id)_$(id)[arrowhead=vee,]\ng$(subgraphs[1].id)->g$(subgraphs[1].id)_$(id)[arrowhead=vee,]\n"
        arrow_temp *= "g$(subgraphs[1].id)_$(id)->$opr_name[arrowhead=vee,]\n"
    else
        arrow_temp *= "g$(subgraphs[1].id)->$opr_name[arrowhead=vee,]\n"
    end
    return node_temp, arrow_temp
end

"""
    function to_dot_str(graphs::AbstractVector{<:AbstractGraph})
    Compile a list of graphs into a string for dot language.
    # Arguments:
    - `graphs`  vector of computational graphs
    - `title`   The name of the complied function (defaults to `"ComputationalGraph"`)
"""
function to_dot_str(graphs::AbstractVector{<:AbstractGraph}, name::String="ComputationalGraph")
    head = "digraph ComputationalGraph { \nlabel=\"$name\"\n"
    head *= "ReturnNode[shape=box, label = \"Return\", style=filled, fillcolor=darkorange,]\n"
    body_node = ""
    body_arrow = ""
    leafidx = 1
    root = [id(g) for g in graphs]
    inds_visitedleaf = Int[]
    inds_visitednode = Int[]
    rootidx = 1
    for graph in graphs
        for g in PostOrderDFS(graph) #leaf first search
            g_id = id(g)
            isroot = false
            if g_id in root
                isroot = true
            end
            if isempty(subgraphs(g)) #leaf
                g_id in inds_visitedleaf && continue
                leafname = getname(g.properties, leafidx)
                if factor(g) == 1
                    gnode_str = "g$g_id[label=$leafname, style=filled, fillcolor=paleturquoise]\n"
                    body_node *= gnode_str
                else
                    factor_str = "factor$(leafidx)_inp[label=$(factor(g)), style=filled, fillcolor=lavender]\n" 
                    leaf_node = "l$(leafidx)[label=$leafname, style=filled, fillcolor=paleturquoise]\n"
                    gnode_str = "g$g_id[shape=box, label = \"Mul\", style=filled, fillcolor=cornsilk,]\n"
                    body_node *= factor_str * leaf_node * gnode_str
                    body_arrow *= "factor$(leafidx)_inp->g$g_id[arrowhead=vee,]\nl$(leafidx)->g$g_id[arrowhead=vee,]\n"
                end
                leafidx += 1
                push!(inds_visitedleaf, g_id)
            else
                g_id in inds_visitednode && continue
                temp_node,temp_arrow = to_dotstatic(operator(g), g_id, factor(g), subgraphs(g), subgraph_factors(g))
                body_node *=temp_node
                body_arrow *= temp_arrow
                push!(inds_visitednode, g_id)
            end
            if isroot
                body_arrow *= "g$(g_id)->ReturnNode[arrowhead=vee,]\n"
                rootidx +=1
            end
        end
    end
    tail = "   }\n"
    expr = head * body_node * body_arrow * tail
    # println(expr)
    return expr
end

function compile_dot(graphs::AbstractVector{<:AbstractGraph}, filename::String; graph_name="ComputationalGraph")
    dot_string = to_dot_str(graphs, graph_name)
    open(filename, "w") do f
        write(f, dot_string)
    end
end

function getname(properties,leafidx)
    if properties isa BareGreenId
        lfname = "<<i>G</i><sub>$leafidx</sub>>"
    elseif properties isa BareInteractionId
        lfname = "<<i>V</i><sub>$leafidx</sub>>"
    elseif typeof(properties) == FeynmanProperties && properties.diagtype == ComputationalGraphs.Propagator
        lfname = "<<i>G</i><sub>$leafidx</sub>>"
    elseif typeof(properties) == FeynmanProperties && properties.diagtype == ComputationalGraphs.Interaction
        lfname = "<<i>V</i><sub>$leafidx</sub>>"
    else
        lfname = "<L<sub>$leafidx</sub>>"
    end
    return lfname
end
