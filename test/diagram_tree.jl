@testset "Diagram" begin
    # Diagram = DiagTreeNew.Diagram
    # DiagramId = DiagTreeNew.DiagramId
    # add_subdiagram! = DiagTreeNew.add_subdiagram!

    struct ID <: DiagramId
        uid::Int
    end
    Base.show(io::IO, d::ID) = print(io, d.uid)
    # Base.isequal(a::ID, b::ID) = (a.index == b.index)
    # Base.Dict(d::ID) = Dict(:id => d.index)

    DiagTree.uidreset()

    W = Int
    ll = Diagram{W}(ID(3))
    l = Diagram{W}(ID(1), Sum(), [ll,])
    r = Diagram{W}(ID(2))
    root = Diagram{W}(ID(0), Sum(), [l, r])

    collect(PostOrderDFS(root))
    @test [node.id.uid for node in PostOrderDFS(root)] == [3, 1, 2, 0]
    @test [node.id.uid for node in PreOrderDFS(root)] == [0, 1, 3, 2]
    @test [node.id.uid for node in Leaves(root)] == [3, 2]

    eval(d::ID) = d.uid
    @test evalDiagTree!(root, eval) == sum(node.id.uid for node in Leaves(root))

    print_tree(root)
    # DiagTreeNew.plot_tree(root)

    println(toDataFrame([root,]))
end

@testset "Generic Diagrams" begin

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
    spin = 2.0
    D = 3
    kF, β, mass2 = 1.919, 0.5, 1.0
    Nk, Nt = 4, 2

    paraG = GenericPara(diagType = GreenDiag,
        innerLoopNum = 0, totalLoopNum = Nk, loopDim = D,
        hasTau = true, totalTauNum = Nt)
    paraV = paraG

    # #construct the propagator table
    gK = [[0.0, 0.0, 1.0, 1.0], [0.0, 0.0, 0.0, 1.0]]
    gT = [(1, 2), (2, 1)]
    g = [Diagram(GreenId(paraG, k = gK[i], t = gT[i]), name = :G) for i in 1:2]

    vdK = [[0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 1.0, 0.0]]
    vdT = [[1, 1], [2, 2]]
    vd = [Diagram(InteractionId(paraV, ChargeCharge, k = vdK[i], permu = Di), name = :Vd) for i in 1:2]

    veK = [[1, 0, -1, -1], [0, 1, 0, -1]]
    veT = [[1, 1], [2, 2]]
    ve = [Diagram(InteractionId(paraV, ChargeCharge, k = veK[i], permu = Ex), name = :Ve) for i in 1:2]

    Id = GenericId(paraV)
    # contruct the tree
    ggn = Diagram(Id, Prod(), [g[1], g[2]])
    vdd = Diagram(Id, Prod(), [vd[1], vd[2]], factor = spin)
    vde = Diagram(Id, Prod(), [vd[1], ve[2]], factor = -1.0)
    ved = Diagram(Id, Prod(), [ve[1], vd[2]], factor = -1.0)
    vsum = Diagram(Id, Sum(), [vdd, vde, ved])
    root = Diagram(Id, Prod(), [vsum, ggn], factor = 1 / (2π)^D, name = :root)

    evalDiagTree!(root, x -> 1.0)
    @test root.weight ≈ -2 + spin

    # #more sophisticated test of the weight evaluation
    varK = rand(D, Nk)
    varT = [rand() * β for t in 1:Nt]

    function evalG(K, τBasis, varT)
        ϵ = dot(K, K) / 2 - kF^2
        τ = varT[τBasis[2]] - varT[τBasis[1]]
        return Spectral.kernelFermiT(τ, ϵ, β)
    end

    evalV(K) = 8π / (dot(K, K) + mass2)

    # # getK(basis, varK) = sum([basis[i] * K for (i, K) in enumerate(varK)])
    getK(basis, varK) = varK * basis

    eval(id::GreenId, varK, varT) = evalG(getK(id.extK, varK), id.extT, varT)
    eval(id::InteractionId, varK, varT) = evalV(getK(id.extK, varK))

    gw = [evalG(getK(gK[i], varK), gT[i], varT) for i = 1:2]
    vdw = [evalV(getK(vdK[i], varK)) for i = 1:2]
    vew = [evalV(getK(veK[i], varK)) for i = 1:2]

    Vweight = spin * vdw[1] * vdw[2] - vdw[1] * vew[2] - vew[1] * vdw[2]
    Weight = gw[1] * gw[2] * Vweight / (2π)^D

    evalDiagTree!(root, eval, varK, varT)

    print_tree(root)

    @test root.weight ≈ Weight
end