    @testset "ShortestPaths.SPFA" begin
        @testset "Generic tests for graphs" begin
            g4 = SimpleDiGraph(SGGEN.Path(5))
            d1 = float([0 1 2 3 4; 5 0 6 7 8; 9 10 0 11 12; 13 14 15 0 16; 17 18 19 20 0])

            @testset "$g" for g in testdigraphs(g4)
                y = @inferred(ShortestPaths.shortest_paths(g, 2, d1, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(y) == [Inf, 0, 6, 17, 33]
            end

            @testset "Graph with cycle" begin
                gx = SimpleGraph(SGGEN.Path(5))
                add_edge!(gx, 2, 4)
                d = ones(Int, 5, 5)
                d[2, 3] = 100
                @testset "$g" for g in testgraphs(gx)
                    z = @inferred(ShortestPaths.shortest_paths(g, 1, d, ShortestPaths.SPFA()))
                    @test ShortestPaths.distances(z) == [0, 1, 3, 2, 3]
                end
            end

            m = [0 2 2 0 0; 2 0 0 0 3; 2 0 0 1 2; 0 0 1 0 1; 0 3 2 1 0]
            G = SimpleGraph(5)
            add_edge!(G, 1, 2)
            add_edge!(G, 1, 3)
            add_edge!(G, 2, 5)
            add_edge!(G, 3, 5)
            add_edge!(G, 3, 4)
            add_edge!(G, 4, 5)

            @testset "$g" for g in testgraphs(G)
                y = @inferred(ShortestPaths.shortest_paths(g, 1, m, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(y) == [0, 2, 2, 3, 4]
            end
        end

        @testset "Graph with self loop" begin
            G = SimpleGraph(5)
            add_edge!(G, 2, 2)
            add_edge!(G, 1, 2)
            add_edge!(G, 1, 3)
            add_edge!(G, 3, 3)
            add_edge!(G, 1, 5)
            add_edge!(G, 2, 4)
            add_edge!(G, 4, 5)
            m = [0 10 2 0 15; 10 9 0 1 0; 2 0 1 0 0; 0 1 0 0 2; 15 0 0 2 0]
            @testset "$g" for g in testgraphs(G)
                z = @inferred(ShortestPaths.shortest_paths(g, 1 , m, ShortestPaths.SPFA()))
                y = @inferred(ShortestPaths.shortest_paths(g, 1, m,ShortestPaths.Dijkstra()))
                @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
            end
        end

        @testset "Disconnected graph" begin
            G = SimpleGraph(5)
            add_edge!(G, 1, 2)
            add_edge!(G, 1, 3)
            add_edge!(G, 4, 5)
            inf = typemax(eltype(G))
            @testset "$g" for g in testgraphs(G)
                z = @inferred(ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(z) == [0, 1, 1, inf, inf]
            end
        end

        @testset "Empty graph" begin
            G = SimpleGraph(3)
            inf = typemax(eltype(G))
            @testset "$g" for g in testgraphs(G)
                z = @inferred(ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(z) == [0, inf, inf]
            end
        end

        @testset "Random Graphs" begin
            @testset "Simple graphs" begin
                for i = 1:5
                    nvg = Int(ceil(250*rand()))
                    neg = Int(floor((nvg*(nvg-1)/2)*rand()))
                    seed = Int(floor(100*rand()))
                    g = SimpleGraph(nvg, neg, rng=MersenneTwister(seed))
                    z = ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA())
                    y = ShortestPaths.shortest_paths(g, 1,ShortestPaths.Dijkstra())
                    @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
                end
            end

            @testset "Simple DiGraphs" begin
                for i = 1:5
                    nvg = Int(ceil(250*rand()))
                    neg = Int(floor((nvg*(nvg-1)/2)*rand()))
                    seed = Int(floor(100*rand()))
                    g = SimpleDiGraph(nvg, neg, rng=MersenneTwister(seed))
                    z = ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA())
                    y = ShortestPaths.shortest_paths(g, 1,ShortestPaths.Dijkstra())
                    @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
                end
            end
        end

        @testset "Different types of graph" begin
            @testset "$g" for g in SimpleGraph.([ SGGEN.Complete(9), SGGEN.Cycle(9), SGGEN.Star(9), SGGEN.Wheel(9), SGGEN.Roach(9), SGGEN.Clique(5, 19)])
                z = ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA())
                y = ShortestPaths.shortest_paths(g, 1, ShortestPaths.Dijkstra())
                @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
            end
            @testset "$g" for g in SimpleDiGraph.([SGGEN.Complete(9), SGGEN.Cycle(9)])
                z = ShortestPaths.shortest_paths(g, 1, ShortestPaths.SPFA())
                y = ShortestPaths.shortest_paths(g, 1, ShortestPaths.Dijkstra())
                @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
            end

        @testset "smallgraphs: $gen" for gen in [
            SGGEN.Bull, SGGEN.Chvatal, SGGEN.Cubical, SGGEN.Desargues,
            SGGEN.Diamond, SGGEN.Dodecahedral, SGGEN.Frucht, SGGEN.Heawood,
            SGGEN.House, SGGEN.HouseX, SGGEN.Icosahedral, SGGEN.KrackhardtKite, SGGEN.MoebiusKantor,
            SGGEN.Octahedral, SGGEN.Pappus, SGGEN.Petersen, SGGEN.SedgewickMaze, SGGEN.Tutte,
            SGGEN.Tetrahedral, SGGEN.TruncatedCube, SGGEN.TruncatedTetrahedron
         ]
            G = SimpleGraph(gen())
            z = ShortestPaths.shortest_paths(G, 1, ShortestPaths.SPFA())
            y = ShortestPaths.shortest_paths(G, 1, ShortestPaths.Dijkstra())
            @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
        end
        @testset "smallgraphs: $gen"  for gen in [SGGEN.TruncatedTetrahedron]
            G = SimpleDiGraph(gen())
            z = ShortestPaths.shortest_paths(G, 1, ShortestPaths.SPFA())
            y = ShortestPaths.shortest_paths(G, 1, ShortestPaths.Dijkstra())
            @test isapprox(ShortestPaths.distances(z), ShortestPaths.distances(y))
        end

        @testset "Normal graph" begin
            g4 = SimpleDiGraph(SGGEN.Path(5))

            d1 = float([0 1 2 3 4; 5 0 6 7 8; 9 10 0 11 12; 13 14 15 0 16; 17 18 19 20 0])
            d2 = sparse(float([0 1 2 3 4; 5 0 6 7 8; 9 10 0 11 12; 13 14 15 0 16; 17 18 19 20 0]))
            @testset "$g" for g in testdigraphs(g4)
                y = @inferred(ShortestPaths.shortest_paths(g, 2, d1, ShortestPaths.SPFA()))
                z = @inferred(ShortestPaths.shortest_paths(g, 2, d2, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(y) == ShortestPaths.distances(z) == [Inf, 0, 6, 17, 33]
                @test @inferred(!ShortestPaths.has_negative_weight_cycle(g, ShortestPaths.SPFA()))
                @test @inferred(!ShortestPaths.has_negative_weight_cycle(g, d1, ShortestPaths.SPFA()))


                y = @inferred(ShortestPaths.shortest_paths(g, 2, d1, ShortestPaths.SPFA()))
                z = @inferred(ShortestPaths.shortest_paths(g, 2, d2, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(y) == ShortestPaths.distances(z) == [Inf, 0, 6, 17, 33]
                @test @inferred(!ShortestPaths.has_negative_weight_cycle(g, ShortestPaths.SPFA()))
                z = @inferred(ShortestPaths.shortest_paths(g, 2, ShortestPaths.SPFA()))
                @test ShortestPaths.distances(z) == [typemax(Int), 0, 1, 2, 3]
            end
        end


        @testset "Negative Cycle" begin
            # Negative Cycle 1
            gx = SimpleGraph(SGGEN.Complete(3))
            @testset "$g" for g in testgraphs(gx)
                d = [1 -3 1; -3 1 1; 1 1 1]
                @test_throws ShortestPaths.NegativeCycleError ShortestPaths.shortest_paths(g, 1, d, ShortestPaths.SPFA())
                @test ShortestPaths.has_negative_weight_cycle(g, d, ShortestPaths.SPFA())

                d = [1 -1 1; -1 1 1; 1 1 1]
                @test_throws ShortestPaths.NegativeCycleError ShortestPaths.shortest_paths(g, 1, d, ShortestPaths.SPFA())
                @test ShortestPaths.has_negative_weight_cycle(g, d, ShortestPaths.SPFA())
            end

            # Negative cycle of length 3 in graph of diameter 4
            gx = SimpleGraph(SGGEN.Complete(4))
            d = [1 -1 1 1; 1 1 1 -1; 1 1 1 1; 1 1 1 1]
            @testset "$g" for g in testgraphs(gx)
                @test_throws ShortestPaths.NegativeCycleError ShortestPaths.shortest_paths(g, 1, d, ShortestPaths.SPFA())
                @test ShortestPaths.has_negative_weight_cycle(g, d, ShortestPaths.SPFA())
            end
        end

        @testset "maximum distance setting limits paths found" begin
            G = SimpleGraph(SGGEN.Cycle(6))
            add_edge!(G, 1, 3)
            m = float([0 2 2 0 0 1; 2 0 1 0 0 0; 2 1 0 4 0 0; 0 0 4 0 1 0; 0 0 0 1 0 1; 1 0 0 0 1 0])

            @testset "$g" for g in testgraphs(G)
                ds = @inferred(ShortestPaths.shortest_paths(G, 3, m, ShortestPaths.SPFA(maxdist=3)))
                @test ShortestPaths.distances(ds) == [2, 1, 0, Inf, Inf, 3]
            end
        end
    end
end
