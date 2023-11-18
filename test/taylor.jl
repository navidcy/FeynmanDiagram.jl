using FeynmanDiagram
using FeynmanDiagram: Taylor as Taylor
using ..DiagTree
function assign_random_numbers(g, taylormap1, taylormap2) #Benchmark taylor expansion generated by two different methods
    leafmap1 = Dict{Int,Int}()
    leafvec1 = Vector{Float64}()
    leafmap2 = Dict{Int,Int}()
    leafvec2 = Vector{Float64}()
    idx = 0
    for leaf in Leaves(g)
        taylor1 = taylormap1[leaf.id]
        taylor2 = taylormap2[leaf.id]
        for (order, coeff) in taylor1.coeffs
            idx += 1
            num = rand()
            push!(leafvec1, num)
            push!(leafvec2, num)
            leafmap1[coeff.id] = idx
            leafmap2[taylor2.coeffs[order].id] = idx
            #print("assign $(order) $(coeff.id)  $(taylor_factorial(order)) $(leafvec[idx])\n")
        end
    end
    return leafmap1, leafvec1, leafmap2, leafvec2
end
@testset verbose = true "TaylorSeries" begin
    using FeynmanDiagram.Taylor:
        getcoeff, set_variables, taylor_factorial, get_numvars
    a, b, c, d, e = set_variables("a b c d e", orders=[3, 3, 3, 3, 3])
    F1 = (a + b) * (a + b) * (a + b)
    print("$(F1)")
    @test getcoeff(F1, [2, 1, 0, 0, 0]) == 3.0
    @test getcoeff(F1, [1, 2, 0, 0, 0]) == 3.0
    @test getcoeff(F1, [3, 0, 0, 0, 0]) == 1.0
    @test getcoeff(F1, [0, 3, 0, 0, 0]) == 1.0
    F2 = (1 + a) * (3 + 2c)
    @test getcoeff(F2, [0, 0, 0, 0, 0]) == 3.0
    @test getcoeff(F2, [1, 0, 0, 0, 0]) == 3.0
    @test getcoeff(F2, [0, 0, 1, 0, 0]) == 2.0
    @test getcoeff(F2, [1, 0, 1, 0, 0]) == 2.0
    F3 = (a + b)^3
    @test getcoeff(F1, [2, 1, 0, 0, 0]) == 3.0
    @test getcoeff(F1, [1, 2, 0, 0, 0]) == 3.0
    @test getcoeff(F1, [3, 0, 0, 0, 0]) == 1.0
    @test getcoeff(F1, [0, 3, 0, 0, 0]) == 1.0
    using FeynmanDiagram.ComputationalGraphs:
        eval!, forwardAD, node_derivative, backAD, build_all_leaf_derivative, count_operation
    using FeynmanDiagram.Utility:
        taylorexpansion!, build_derivative_backAD!
    g1 = Graph([])
    g2 = Graph([])
    g3 = Graph([], factor=2.0)
    G3 = g1
    G4 = 1.0 * g1 * g1
    G5 = 1.0 * (3.0 * G3 + 0.5 * G4)
    G6 = (1.0 * g1 + 2.0 * g2) * (g1 + g3)

    set_variables("x y z", orders=[2, 3, 2])
    var_dependence = Dict{Int,Vector{Bool}}()
    for G in [G3, G4, G5, G6]
        for leaf in Leaves(G)
            if !haskey(var_dependence, leaf.id)
                var_dependence[leaf.id] = [true for _ in 1:get_numvars()]
            end
        end
        T, taylormap, from_coeff_map = taylorexpansion!(G, var_dependence)
        for leaf in Leaves(G)
            t = taylormap[leaf.id]
            for (order, coeff) in t.coeffs
                @test from_coeff_map[coeff.id] == (leaf.id, order)
            end
        end
        T_compare, taylormap_compare = build_derivative_backAD!(G)
        leafmap1, leafvec1, leafmap2, leafvec2 = assign_random_numbers(G, taylormap, taylormap_compare)
        for (order, coeff) in T_compare.coeffs
            @test eval!(coeff, leafmap2, leafvec2) ≈ taylor_factorial(order) * eval!(T.coeffs[order], leafmap1, leafvec1)
        end
    end

end




@testset "Taylor AD of Sigma FeynmanGraph" begin
    dict_g, lp, leafmap = diagdictGV(:sigma, [(2, 0, 0), (2, 0, 1), (2, 0, 2), (2, 1, 0), (2, 1, 1), (2, 2, 0), (2, 1, 2), (2, 2, 2)])

    g = dict_g[(2, 0, 0)]

    set_variables("x y", orders=[2, 2])
    propagator_var = ([true, false], [false, true]) # Specify variable dependence of fermi (first element) and bose (second element) particles.
    t, taylormap, from_coeff_map = taylorexpansion!(g[1][1], propagator_var)
    for leaf in Leaves(g[1][1])
        taylor = taylormap[leaf.id]
        for (order, coeff) in taylor.coeffs
            @test from_coeff_map[coeff.id] == (leaf.id, order)
        end
    end
    for (order, graph) in dict_g
        if graph[2][1] == g[2][1]
            idx = 1
        else
            idx = 2
        end
        #print("$(order) $(eval!(graph[1][idx])) $(eval!(t.coeffs[[order[2],order[3]]]))\n")
        @test eval!(graph[1][idx]) == eval!(t.coeffs[[order[2], order[3]]])
    end
end


function getdiagram(spin=2.0, D=3, Nk=4, Nt=2)
    """
        k1-k3                     k2+k3 
        |                         | 
    t1.L ↑     t1.L       t2.L     ↑ t2.L
        |-------------->----------|
        |       |  k3+k4   |      |
        |   v   |          |  v   |
        |       |    k4    |      |
        |--------------<----------|
    t1.L ↑    t1.L        t2.L     ↑ t2.L
        |                         | 
        k1                        k2
    """

    DiagTree.uidreset()
    # We only consider the direct part of the above diagram

    paraG = DiagParaF64(type=GreenDiag,
        innerLoopNum=0, totalLoopNum=Nk, loopDim=D,
        hasTau=true, totalTauNum=Nt)
    paraV = paraG

    # #construct the propagator table
    gK = [[0.0, 0.0, 1.0, 1.0], [0.0, 0.0, 0.0, 1.0]]
    gT = [(1, 2), (2, 1)]
    g = [Diagram{Float64}(BareGreenId(paraG, k=gK[i], t=gT[i]), name=:G) for i in 1:2]

    vdK = [[0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 1.0, 0.0]]
    # vdT = [[1, 1], [2, 2]]
    vd = [Diagram{Float64}(BareInteractionId(paraV, ChargeCharge, k=vdK[i], permu=Di), name=:Vd) for i in 1:2]

    veK = [[1, 0, -1, -1], [0, 1, 0, -1]]
    # veT = [[1, 1], [2, 2]]
    ve = [Diagram{Float64}(BareInteractionId(paraV, ChargeCharge, k=veK[i], permu=Ex), name=:Ve) for i in 1:2]

    Id = GenericId(paraV)
    # contruct the tree
    ggn = Diagram{Float64}(Id, Prod(), [g[1], g[2]])
    vdd = Diagram{Float64}(Id, Prod(), [vd[1], vd[2]], factor=spin)
    vde = Diagram{Float64}(Id, Prod(), [vd[1], ve[2]], factor=-1.0)
    ved = Diagram{Float64}(Id, Prod(), [ve[1], vd[2]], factor=-1.0)
    vsum = Diagram{Float64}(Id, Sum(), [vdd, vde, ved])
    root = Diagram{Float64}(Id, Prod(), [vsum, ggn], factor=1 / (2π)^D, name=:root)

    return root, gK, gT, vdK, veK
end

function assign_leaves(g::Diagram, taylormap) #This should be written more generic later. 
    #For bench mark purpose, currently it assigns taylor coefficients of leaves with 1.0 / taylor_factorial(order)) so that it corresponds to assign all derivatives with 1.
    leafmap = Dict{Int,Int}()
    leafvec = Vector{Float64}()
    idx = 0
    for leaf in Leaves(g)
        taylor = taylormap[leaf.hash]
        for (order, coeff) in taylor.coeffs
            idx += 1
            push!(leafvec, 1.0 / taylor_factorial(order))
            leafmap[coeff.id] = idx
            #print("assign $(order) $(coeff.id)  $(taylor_factorial(order)) $(leafvec[idx])\n")
        end
    end
    return leafmap, leafvec
end


@testset "Taylor AD of DiagTree" begin


    DiagTree.uidreset()
    # We only consider the direct part of the above diagram
    spin = 0.5
    D = 3
    kF, β, mass2 = 1.919, 0.5, 1.0
    Nk, Nt = 4, 2

    root, gK, gT, vdK, veK = getdiagram(spin, D, Nk, Nt)

    #optimize the diagram
    DiagTree.optimize!([root,])

    # autodiff
    droot_dg = DiagTree.derivative([root,], BareGreenId)[1]
    droot_dv = DiagTree.derivative([root,], BareInteractionId)[1]
    droot_dvdg = DiagTree.derivative([droot_dg,], BareInteractionId)[1]
    droot_dvdv = DiagTree.derivative([droot_dv,], BareInteractionId)[1]
    droot_dgdg = DiagTree.derivative([droot_dg,], BareGreenId)[1]
    # plot_tree(droot_dg)
    factor = 1 / (2π)^D
    DiagTree.eval!(root; eval=(x -> 1.0))
    @test root.weight ≈ (-2 + spin) * factor

    DiagTree.eval!(droot_dg; eval=(x -> 1.0))
    @test droot_dg.weight ≈ (-2 + spin) * 2 * factor

    DiagTree.eval!(droot_dv; eval=(x -> 1.0))
    @test droot_dv.weight ≈ (-2 + spin) * 2 * factor

    DiagTree.eval!(droot_dvdv; eval=(x -> 1.0))
    @test droot_dv.weight ≈ (-2 + spin) * 2 * factor

    DiagTree.eval!(droot_dvdg; eval=(x -> 1.0))
    @test droot_dv.weight ≈ (-2 + spin) * 2 * factor

    DiagTree.eval!(droot_dgdg; eval=(x -> 1.0))
    @test droot_dv.weight ≈ (-2 + spin) * 2 * factor

    set_variables("x y"; orders=[2, 2])

    propagator_var = Dict(DiagTree.BareGreenId => [true, false], DiagTree.BareInteractionId => [false, true]) # Specify variable dependence of fermi (first element) and bose (second element) particles.
    t, taylormap, from_coeff_map = taylorexpansion!(root, propagator_var)
    for leaf in PostOrderDFS(root)
        if isempty(leaf.subdiagram)
            taylor = taylormap[leaf.hash]
            for (order, coeff) in taylor.coeffs
                @test from_coeff_map[coeff.id] == (leaf.hash, order)
            end
        end
    end
    taylorleafmap, taylorleafvec = assign_leaves(root, taylormap)
    @test eval!(t.coeffs[[0, 0]], taylorleafmap, taylorleafvec) ≈ root.weight
    @test eval!(t.coeffs[[0, 1]], taylorleafmap, taylorleafvec) ≈ droot_dv.weight / taylor_factorial([0, 1])
    @test eval!(t.coeffs[[1, 0]], taylorleafmap, taylorleafvec) ≈ droot_dg.weight / taylor_factorial([1, 0])
    @test eval!(t.coeffs[[1, 1]], taylorleafmap, taylorleafvec) ≈ droot_dvdg.weight / taylor_factorial([1, 1])
    @test eval!(t.coeffs[[2, 0]], taylorleafmap, taylorleafvec) ≈ droot_dgdg.weight / taylor_factorial([2, 0])
    @test eval!(t.coeffs[[0, 2]], taylorleafmap, taylorleafvec) ≈ droot_dvdv.weight / taylor_factorial([0, 2])
end

