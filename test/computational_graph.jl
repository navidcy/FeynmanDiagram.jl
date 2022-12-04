@testset "Contractions" begin
    # Test 1: Scalar fields with Wick crossings, parity = +1
    vertices1 = [𝜙(1)𝜙(2), 𝜙(3)𝜙(4)𝜙(5)𝜙(6), 𝜙(7)𝜙(8)]
    edges1, parity1 = contractions_to_edges(vertices1; contractions=[1, 2, 3, 4, 1, 3, 4, 2])
    ops = reduce(*, vertices1)
    @test Set(edges1) == Set([(ops[1], ops[5]), (ops[2], ops[8]), (ops[3], ops[6]), (ops[4], ops[7])])
    @test parity1 == 1

    # Test 2: Bosons with Wick crossings, parity = +1
    vertices2 = [𝑏⁺(1)𝑏⁺(2)𝑏⁻(3), 𝑏⁻(4)𝑏⁺(5), 𝑏⁻(6)𝑏⁺(7)𝑏⁻(8)]
    edges2, parity2 = contractions_to_edges(vertices2; contractions=[1, 2, 3, 4, 3, 1, 4, 2])
    ops = reduce(*, vertices2)
    # @test Set(edges2) == Set([(ops[1], ops[6]), (ops[2], ops[8]), (ops[5], ops[3]), (ops[7], ops[4])])
    @test Set(edges2) == Set([(ops[1], ops[6]), (ops[2], ops[8]), (ops[3], ops[5]), (ops[4], ops[7])])
    @test parity2 == 1

    # Test 3: Indistinguishable Majoranas with no Wick crossings, parity = +1
    vertices3 = [𝑓(1)𝑓(1)𝑓(1)𝑓(1)𝑓(1)𝑓(1)𝑓(1)𝑓(1),]
    edges3, parity3 = contractions_to_edges(vertices3; contractions=[1, 2, 3, 4, 4, 3, 2, 1])
    ops = reduce(*, vertices3)
    @test Set(edges3) == Set([(ops[1], ops[8]), (ops[2], ops[7]), (ops[3], ops[6]), (ops[4], ops[5])])
    # P = (1 8 2 7 3 6 4 5) = (1)(5 3 2 8)(4 7)(6) => parity = +1
    @test parity3 == 1

    # Test 4: Fermions with Wick crossings, parity = -1
    vertices4 = [𝑓⁺(1)𝑓⁻(2), 𝑓⁺(5)𝑓⁺(6)𝑓⁻(7)𝑓⁻(8), 𝑓⁺(3)𝑓⁻(4),]
    edges4, parity4 = contractions_to_edges(vertices4; contractions=[1, 2, 2, 3, 1, 4, 4, 3])
    ops = reduce(*, vertices4)
    # @test Set(edges4) == Set([(ops[1], ops[5]), (ops[3], ops[2]), (ops[4], ops[8]), (ops[7], ops[6])])
    @test Set(edges4) == Set([(ops[1], ops[5]), (ops[2], ops[3]), (ops[4], ops[8]), (ops[6], ops[7])])
    # P = (1 5 2 3 4 8 6 7) = (1)(2 5 4)(3)(6 8)(7) => parity = -1
    @test parity4 == -1

    # Test 5: Mixed bosonic/classical/fermionic operators, parity = -1
    vertices5 = [𝑏⁺(1)𝑓⁺(2)𝜙(3), 𝑓⁻(4)𝑓⁻(5), 𝑏⁻(6)𝑓⁺(7)𝜙(8)]
    ops = reduce(*, vertices5)
    edges5, parity5 = contractions_to_edges(vertices5; contractions=[1, 2, 3, 2, 4, 1, 4, 3])
    # @test Set(edges5) == Set([(ops[1], ops[6]), (ops[2], ops[4]), (ops[3], ops[8]), (ops[7], ops[5])])
    @test Set(edges5) == Set([(ops[1], ops[6]), (ops[2], ops[4]), (ops[3], ops[8]), (ops[5], ops[7])])
    # Flattened fermionic edges: [2, 4, 5, 7]
    # => P = (1 2 3 4) = (1)(2)(3 4) => parity = 1
    @test parity5 == 1
end

@testset "feynman_diagram" begin
    # phi theory 
    V1 = [𝜙(1)𝜙(2)𝜙(3)𝜙(4),]
    g1 = feynman_diagram(V1, [1, 1, 2, 2])
    @test vertices(g1) == V1
    @test isempty(external_vertices(g1))
    @test internal_vertices(g1) == V1

    #complex scalar field
    V2 = [𝑏⁺(1), 𝑏⁺(2)𝑏⁺(3)𝑏⁻(4)𝑏⁻(5), 𝑏⁺(6)𝑏⁺(7)𝑏⁻(8)𝑏⁻(9), 𝑏⁻(10)]
    g2 = feynman_diagram(V2, [1, 2, 3, 4, 1, 4, 5, 2, 3, 5]; external=[1, 4])
    @test vertices(g2) == V2
    @test external_vertices(g2) == [V2[1], V2[4]]
    @test internal_vertices(g2) == V2[2:3]

    # Yukawa 
    V3 = [𝑓⁺(1)𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5)𝜙(6)]
    g3 = feynman_diagram(V3, [1, 2, 3, 2, 1, 3])
    @test vertices(g3) == V3
    @test isempty(external_vertices(g3))
    @test internal_vertices(g3) == V3
    # @test g3.subgraph[1] == propagator(𝑓⁺(1), 𝑓⁻(5))  #isequal except for id 
    @test g3.subgraph[1].factor == -1
    @test g3.subgraph[2].factor == 1
    @test g3.subgraph[3].factor == 1

    V4 = [𝑓⁺(1)𝑓⁻(2), 𝑓⁺(3)𝑓⁻(4), 𝑓⁺(5)𝑓⁻(6)𝜙(7), 𝑓⁺(8)𝑓⁻(9)𝜙(10)]
    g4 = feynman_diagram(V4, [1, 2, 3, 4, 4, 1, 5, 2, 3, 5], external=[1, 2])
    @test vertices(g4) == V4
    @test external_vertices(g4) == V4[1:2]
    @test internal_vertices(g4) == V4[3:4]
    @test g4.subgraph[1].factor == -1
    @test g4.subgraph[2].factor == 1
    @test g4.subgraph[3].factor == -1
    @test g4.subgraph[4].factor == 1
    @test g4.subgraph[5].factor == 1

    V5 = [𝑓⁻(2)𝜙(3), 𝑓⁺(4)𝑓⁻(5), 𝑓⁺(6)𝜙(7)]
    g5 = feynman_diagram(V5, [1, 2, 1, 3, 3, 2], external=[1, 2, 3])
    @test vertices(g5) == V5
    @test external_vertices(g5) == V5
    @test isempty(internal_vertices(g5))
    @test g5.subgraph[1].factor == 1
    @test g5.subgraph[2].factor == 1
    @test g5.subgraph[3].factor == 1
end