@testset verbose = true "Graph" begin
    V = [interaction(𝑓⁺(1)𝑓⁻(2)𝑓⁺(3)𝑓⁻(4)), interaction(𝑓⁺(5)𝑓⁺(6)𝑓⁻(7)𝑓⁻(8)),
        external_vertex(𝑓⁺(9)), external_vertex(𝑓⁺(10))]
    g1 = Graph(V; topology=[[2, 6], [3, 7], [4, 9], [8, 10]],
        external=[1, 5, 9, 10], hasLeg=[false, false, true, true])
    g2 = g1 * 2
    @testset "Graph equivalence" begin
        g1p = Graph(V, topology=[[2, 6], [3, 7], [4, 9], [8, 10]],
            external=[1, 5, 9, 10], hasLeg=[false, false, true, true])
        g2p = Graph(V, topology=[[2, 6], [3, 7], [4, 9], [8, 10]],
            external=[1, 5, 9, 10], hasLeg=[false, false, true, true], factor=2)
        # Test equivalence modulo fields id/factor
        @test isequiv(g1, g1p) == false
        @test isequiv(g1, g2p, :id) == false
        @test isequiv(g1, g2p, :factor) == false
        @test isequiv(g1, g1p, :id)
        @test isequiv(g1, g2p, :id, :factor)
        # Test inequivalence when subgraph lengths are different
        t = g1 + g1
        @test isequiv(t, g1, :id) == false
    end
    @testset "Scalar multiplication" begin
        @test vertices(g2) == vertices(g1)
        println(external(g2))
        println(external(g1))
        @test external(g2) == external(g1)
        @test g2.subgraph_factors == [2]
        @test g2.operator == ComputationalGraphs.Prod
        g2 = 2g1
        @test vertices(g2) == vertices(g1)
        @test external(g2) == external(g1)
        @test g2.subgraph_factors == [2]
        @test g2.operator == ComputationalGraphs.Prod
    end
    @testset "Graph addition" begin
        g3 = g1 + g2
        @test vertices(g3) == vertices(g1)
        @test external(g3) == external(g1)
        @test g3.factor == 1
        @test g3.subgraphs == [g1, g2]
        @test g3.subgraph_factors == [1, 1]
        @test g3.subgraphs[1].subgraph_factors == g1.subgraph_factors
        @test g3.subgraphs[2].subgraph_factors == [2]
        @test g3.operator == ComputationalGraphs.Sum
    end
    @testset "Graph subtraction" begin
        g4 = g1 - g2
        @test vertices(g4) == vertices(g1)
        @test external(g4) == external(g1)
        @test g4.factor == 1
        @test g4.subgraphs == [g1, g2]
        @test g4.subgraph_factors == [1, -1]
        @test g4.subgraphs[1].subgraph_factors == g1.subgraph_factors
        @test g4.subgraphs[2].subgraph_factors == [2]
        @test g4.subgraphs[2].subgraphs[1].factor == 1
        @test g4.operator == ComputationalGraphs.Sum
    end
    @testset "Linear combinations" begin
        # Binary form
        g5 = 3g1 + 5g2
        g5lc = ComputationalGraphs.linear_combination(g1, g2, 3, 5)
        @test g5.subgraph_factors == [1, 1]
        @test [g.subgraph_factors[1] for g in g5.subgraphs] == [3, 10]
        @test g5lc.subgraphs == [g1, g2]
        @test g5lc.subgraph_factors == [3, 5]
        # Requires optimization merge_prefactors on g5
        @test_broken isequiv(g5, g5lc, :id)
        # Vector form
        g6lc = ComputationalGraphs.linear_combination([g1, g2, g5, g2, g1], [3, 5, 7, 9, 11])
        @test g6lc.subgraphs == [g1, g2, g5, g2, g1]
        @test g6lc.subgraph_factors == [3, 5, 7, 9, 11]
    end
    @testset "Multiplicative chains" begin
        g6 = 7 * (5 * (3 * (2 * g1)))
        @test g6.subgraph_factors == [210]
        @test g6.subgraphs[1].subgraphs == g1.subgraphs
        @test g6.subgraphs[1].subgraph_factors == g1.subgraph_factors
        g7 = (((g1 * 2) * 3) * 5) * 7
        @test g7.subgraph_factors == [210]
        @test g7.subgraphs[1].subgraphs == g1.subgraphs
        @test g7.subgraphs[1].subgraph_factors == g1.subgraph_factors
    end
end

@testset "propagator" begin
    g1 = propagator(𝑓⁺(1)𝑓⁻(2))
    # g1 = propagator([𝑓⁺(1), 𝑓⁻(2)])
    @test g1.factor == -1
    @test g1.external == [2, 1]
    @test vertices(g1) == [𝑓⁺(1), 𝑓⁻(2)]
    @test external(g1) == 𝑓⁻(2)𝑓⁺(1)
    @test external_labels(g1) == [2, 1]
end

@testset "interaction" begin
    ops = 𝑓⁺(1)𝑓⁻(2)𝑓⁻(3)𝑓⁺(4)𝜙(5)
    g1 = interaction(ops)
    @test g1.factor == 1
    @test g1.external == [1, 2, 3, 4, 5]
    @test vertices(g1) == [ops]
    @test external(g1) == ops
    @test external_labels(g1) == [1, 2, 3, 4, 5]

    g2 = interaction(ops, reorder=normal_order)
    @test g2.factor == -1
    @test vertices(g2) == [ops]
    @test external(g2) == 𝑓⁺(1)𝑓⁺(4)𝜙(5)𝑓⁻(3)𝑓⁻(2)
    @test external_labels(g2) == [1, 4, 5, 3, 2]
end

@testset verbose = true "feynman_diagram" begin
    @testset "Phi4" begin
        # phi theory 
        V1 = [interaction(𝜙(1)𝜙(2)𝜙(3)𝜙(4))]
        g1 = feynman_diagram(V1, [[1, 2], [3, 4]])    #vacuum diagram
        # g1 = feynman_diagram(V1, [1, 1, 2, 2])
        @test vertices(g1) == [𝜙(1)𝜙(2)𝜙(3)𝜙(4)]
        @test isempty(external(g1))
        @test g1.subgraph_factors == [1, 1, 1]
    end
    @testset "Complex scalar field" begin
        #complex scalar field
        V2 = [𝑏⁺(1), 𝑏⁺(2)𝑏⁺(3)𝑏⁻(4)𝑏⁻(5), 𝑏⁺(6)𝑏⁺(7)𝑏⁻(8)𝑏⁻(9), 𝑏⁻(10)]
        # g2 = feynman_diagram(V2, [1, 2, 3, 4, 1, 4, 5, 2, 3, 5]; external=[1, 10])
        g2V = [external_vertex(V2[1]), interaction(V2[2]), interaction(V2[3]), external_vertex(V2[4])]
        g2 = feynman_diagram(g2V, [[1, 5], [2, 8], [3, 9], [4, 6], [7, 10]])    # Green2
        @test vertices(g2) == V2
        @test external(g2) == 𝑏⁺(1)𝑏⁻(10)
        @test g2.subgraph_factors == ones(Int, 9)
    end
    @testset "Yukawa interaction" begin
        # Yukawa 
        V3 = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6)]
        # g3 = feynman_diagram(V3, [1, 2, 3, 2, 1, 3])
        g3 = feynman_diagram(interaction.(V3), [[1, 5], [2, 4], [3, 6]])  #vacuum diagram
        @test vertices(g3) == V3
        @test isempty(external(g3))
        @test g3.factor == 1
        @test g3.subgraph_factors == ones(Int, 5)
        @test g3.subgraphs[3].factor == -1
        @test g3.subgraphs[3].vertices == [𝑓⁺(1), 𝑓⁻(5)]
        @test external(g3.subgraphs[3]) == 𝑓⁻(5)𝑓⁺(1)

        V4 = [𝑓⁺(1)𝑓⁻(2), 𝑓⁺(3)𝑓⁻(4)𝜙(5), 𝑓⁺(6)𝑓⁻(7)𝜙(8), 𝑓⁺(9)𝑓⁻(10)]
        g4 = feynman_diagram([external_vertex(V4[1]), interaction.(V4[2:3])..., external_vertex(V4[4])],
            [[1, 4], [2, 6], [3, 10], [5, 8], [7, 9]]) # polarization diagram
        @test g4.factor == -1
        @test g4.subgraph_factors == ones(Int, 9)
        @test vertices(g4) == V4
        @test external(g4) == 𝑓⁺(1)𝑓⁻(2)𝑓⁺(9)𝑓⁻(10)

        V5 = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6), 𝑓⁺(7)𝑓⁻(8)𝜙(9)]
        g5 = feynman_diagram(interaction.(V5), [[1, 5], [3, 9], [4, 8]])  # vertex function
        @test g5.factor == -1
        @test g5.subgraph_factors == ones(Int, 6)
        @test vertices(g5) == V5
        @test external(g5) == 𝑓⁻(2)𝜙(6)𝑓⁺(7)
        g5p = feynman_diagram(interaction.(V5), [[1, 5], [3, 9], [4, 8]], [3, 1, 2])
        @test g5.factor ≈ -g5p.factor    # reorder of external fake legs will not change the sign.
        @test g5p.subgraph_factors == ones(Int, 6)
        @test external(g5p) == 𝑓⁺(7)𝑓⁻(2)𝜙(6)

        V6 = [𝑓⁻(8), 𝑓⁺(1), 𝑓⁺(2)𝑓⁻(3)𝜙(4), 𝑓⁺(5)𝑓⁻(6)𝜙(7)]
        g6 = feynman_diagram([external_vertex.(V6[1:2]); interaction.(V6[3:4])], [[2, 4], [3, 7], [5, 8], [6, 1]])    # fermionic Green2
        @test g6.factor == -1
        @test g6.subgraph_factors == ones(Int, 8)
        @test external(g6) == 𝑓⁻(8)𝑓⁺(1)

        V7 = [𝑓⁻(7), 𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6)]
        g7 = feynman_diagram([external_vertex(V7[1]), interaction.(V7[2:3])...], [[2, 6], [4, 7], [5, 1]])     # sigma*G
        @test g7.factor == 1
        @test external(g7) == 𝑓⁻(7)𝑓⁻(2)

        V8 = [𝑓⁺(2), 𝑓⁻(12), 𝑓⁺(3)𝑓⁻(4)𝜙(5), 𝑓⁺(6)𝑓⁻(7)𝜙(8), 𝑓⁺(9)𝑓⁻(10)𝜙(11), 𝑓⁺(13)𝑓⁻(14)𝜙(15)]
        g8 = feynman_diagram([external_vertex.(V8[1:2]); interaction.(V8[3:end])], [[1, 4], [3, 7], [5, 14], [6, 13], [8, 11], [9, 2]])
        @test g8.factor == -1
        @test vertices(g8) == V8
        @test external(g8) == 𝑓⁺(2)𝑓⁻(12)𝑓⁻(10)𝑓⁺(13)

        g8p = feynman_diagram([external_vertex.(V8[1:2]); interaction.(V8[3:end])],
            [[1, 4], [3, 7], [5, 14], [6, 13], [8, 11], [9, 2]], [2, 1])
        @test g8p.factor == 1
        @test external(g8p) == 𝑓⁺(2)𝑓⁻(12)𝑓⁺(13)𝑓⁻(10)
    end
    @testset "f+f+f-f- interaction" begin
        V1 = [𝑓⁺(3), 𝑓⁺(4), 𝑓⁺(5)𝑓⁺(6)𝑓⁻(7)𝑓⁻(8), 𝑓⁺(9)𝑓⁺(10)𝑓⁻(11)𝑓⁻(12)]
        g1 = feynman_diagram([external_vertex.(V1[1:2]); interaction.(V1[3:4])], [[1, 6], [2, 9], [4, 10], [5, 7]])
        g1p = feynman_diagram([external_vertex.(V1[2:-1:1]); interaction.(V1[3:4])],
            [[2, 6], [1, 9], [4, 10], [5, 7]], [2, 1])
        @test g1p.factor ≈ g1.factor
        @test external(g1) == 𝑓⁺(3)𝑓⁺(4)𝑓⁺(5)𝑓⁺(10)
        @test vertices(g1p) == [𝑓⁺(4), 𝑓⁺(3), 𝑓⁺(5)𝑓⁺(6)𝑓⁻(7)𝑓⁻(8), 𝑓⁺(9)𝑓⁺(10)𝑓⁻(11)𝑓⁻(12)]
        @test external(g1p) == 𝑓⁺(4)𝑓⁺(3)𝑓⁺(10)𝑓⁺(5)

        V2 = [𝑓⁺(2), 𝑓⁻(3), 𝑓⁺(4)𝑓⁺(5)𝑓⁻(6)𝑓⁻(7), 𝑓⁺(8)𝑓⁺(9)𝑓⁻(10)𝑓⁻(11)]
        g2 = feynman_diagram([external_vertex.(V2[1:2]); interaction.(V2[3:4])], [[1, 6], [2, 3], [4, 10], [5, 8]])
        @test g2.factor == -1
        @test external(g2) == 𝑓⁺(2)𝑓⁻(3)𝑓⁺(8)𝑓⁻(10)
        @test external_labels(g2) == [2, 3, 8, 10] # labels of external vertices    
    end
    # @testset "Multi-operator contractions" begin
    #     # multi-operator (>2) contractions
    #     Vm = [𝑓ₑ(1), 𝑓⁺(2)𝑓⁻(3)𝑏⁺(4), 𝜙(5)𝑓⁺(6)𝑓⁻(7), 𝑓(8)𝑏⁻(9)𝜙(10)]
    #     gm = feynman_diagram(Vm, [[2, 3, 4, 9], [5, 6, 7, 10], [8, 1]], external=[8])
    #     @test vertices(gm) == Vm
    #     @test gm.subgraph_factors == [1, 1]
    #     @test gm.subgraphs[1].vertices == external(gm.subgraphs[1]) == [𝑓⁺(2), 𝑓⁻(3), 𝑏⁺(4), 𝑏⁻(9)]
    #     @test gm.subgraphs[2].vertices == external(gm.subgraphs[2]) == [𝜙(5), 𝑓⁺(6), 𝑓⁻(7), 𝜙(10)]
    #     @test external_with_ghost(gm) == [𝑓ₑ(1)]
    #     @test external(gm) == [𝑓(8)]
    #     standardize_order!(gm)
    #     @test gm.subgraphs[1].factor == -1
    #     @test external(gm.subgraphs[1]) == [𝑓⁻(3), 𝑏⁻(9), 𝑏⁺(4), 𝑓⁺(2)]
    #     @test gm.subgraphs[2].factor == -1
    #     @test external(gm.subgraphs[2]) == [𝜙(5), 𝑓⁻(7), 𝜙(10), 𝑓⁺(6)]

    #     ggm = deepcopy(gm)
    #     ggm.id = 1000
    #     @test isequiv(gm, ggm, :id)
    # end
    @testset "Construct feynman diagram from sub-diagrams" begin
        V1 = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6)]
        g1 = feynman_diagram(interaction.(V1), [[3, 6]])
        V2 = [𝑓⁺(7)𝑓⁻(8)𝜙(9), 𝑓⁺(10)𝑓⁻(11)𝜙(12)]
        g2 = feynman_diagram(interaction.(V2), [[3, 6]])

        V3 = [𝑓⁻(13), 𝑓⁻(14), 𝑓⁺(15), 𝑓⁺(16)]
        g = feynman_diagram([g1, g2, external_vertex.(V3)...], [[1, 6], [2, 12], [3, 9], [4, 5], [7, 10], [8, 11]])

        @test vertices(g) == [𝑓⁺(1)𝑓⁻(2)𝑓⁺(4)𝑓⁻(5), 𝑓⁺(7)𝑓⁻(8)𝑓⁺(10)𝑓⁻(11), V3...]
        @test external(g) == reduce(*, V3)
    end

end

@testset "relabel and standardize_labels" begin
    using FeynmanDiagram.ComputationalGraphs

    @testset "relabel" begin
        # construct a graph
        V = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6), 𝑓⁺(7)𝑓⁻(8)𝜙(9)]
        g1 = feynman_diagram(interaction.(V), [[1, 5], [3, 9], [4, 8]])

        map = Dict(3 => 1, 4 => 1, 5 => 1, 9 => 1, 8 => 1)
        g2 = relabel(g1, map)
        uniqlabels = ComputationalGraphs.collect_labels(g2)
        @test uniqlabels == [1, 2, 6, 7]

        map = Dict([i => 1 for i in 2:9])
        g3 = relabel(g1, map)
        uniqlabels = ComputationalGraphs.collect_labels(g3)
        @test uniqlabels == [1,]
    end

    @testset "standardize_labels" begin
        V = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6), 𝑓⁺(7)𝑓⁻(8)𝜙(9), 𝑓⁺(10)]
        g1 = feynman_diagram([interaction.(V[1:3])..., external_vertex(V[end])], [[1, 5], [3, 9], [4, 8], [2, 10]])

        map = Dict([i => (11 - i) for i in 1:5])
        g2 = relabel(g1, map)

        g3 = standardize_labels(g2)
        uniqlabels = ComputationalGraphs.collect_labels(g3)
        @test uniqlabels == [1, 2, 3, 4, 5]
    end
end

@testset "graph vector" begin
    import FeynmanDiagram.ComputationalGraphs as Graphs

    p1 = Graphs.propagator(𝑓⁺(1)𝑓⁻(2))
    p2 = Graphs.propagator(𝑓⁺(1)𝑓⁻(3))
    p3 = Graphs.propagator(𝑓⁺(2)𝑓⁻(3))

    gv = [p1, p2, p3]

    g1 = Graphs.group(gv, [2,])
    @test Set(g1[[𝑓⁺(1),]]) == Set([p1, p2])
    @test Set(g1[[𝑓⁺(2),]]) == Set([p3,])

    g2 = Graphs.group(gv, [1,])
    @test Set(g2[[𝑓⁻(2),]]) == Set([p1,])
    @test Set(g2[[𝑓⁻(3),]]) == Set([p2, p3])

    g3 = Graphs.group(gv, [2, 1])
    @test Set(g3[[𝑓⁺(1), 𝑓⁻(2)]]) == Set([p1,])
    @test Set(g3[[𝑓⁺(1), 𝑓⁻(3)]]) == Set([p2,])
    @test Set(g3[[𝑓⁺(2), 𝑓⁻(3)]]) == Set([p3,])
end
