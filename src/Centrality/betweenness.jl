# Betweenness centrality measures
# TODO - weighted, separate unweighted, edge betweenness

"""
    struct Betweenness{T<:AbstractVector{<:Integer}} <: CentralityMeasure
        normalize::Bool
        endpoints::Bool
        k::Int
        vs::U
    end
        
A struct representing an algorithm to calculate the [betweenness centrality](https://en.wikipedia.org/wiki/Centrality#Betweenness_centrality)
of a graph `g` across all vertices, a specified subset of vertices `vs`, and/or a random subset of `k` vertices. 

### Optional Arguments
- `normalize=true`: If true, normalize the betweenness values by the
total number of possible distinct paths between all pairs in the graphs.
For an undirected graph, this number is ``\\frac{(|V|-1)(|V|-2)}{2}``
and for a directed graph, ``{(|V|-1)(|V|-2)}``.
- `endpoints=false`: If true, include endpoints in the shortest path count.
- `k=0`: If `k>0`, randomly sample `k` vertices from `vs` if provided, or from `vertices(g)` if empty.
- `vs=[]`: if `vs` is nonempty, run betweenness centrality only from these vertices.

Betweenness centrality is defined as:
``
bc(v) = \\frac{1}{\\mathcal{N}} \\sum_{s \\neq t \\neq v}
\\frac{\\sigma_{st}(v)}{\\sigma_{st}}
``.

### References
- Brandes 2001 & Brandes 2008

# Examples
```jldoctest
julia> using LightGraphs

julia> centrality(star_graph(3), Betweenness())
3-element Array{Float64,1}:
 1.0
 0.0
 0.0

 julia> centrality(path_graph(4), Betweenness())
4-element Array{Float64,1}:
 0.0
 0.6666666666666666
 0.6666666666666666
 0.0
```
"""
struct Betweenness{T<:AbstractVector{<:Integer}} <: CentralityMeasure
    normalize::Bool
    endpoints::Bool
    k::Int
    vs::T
end

Betweenness(; normalize=true, endpoints=false, k=0, vs=Vector{Int}()) = Betweenness(normalize, endpoints, k, vs)

function centrality(g::AbstractGraph, distmx::AbstractMatrix, alg::Betweenness)
    vs = isempty(alg.vs) ? vertices(g) : alg.vs
    if alg.k > 0
        sample!(vs, alg.k)
    end

    return _betweenness_centrality(g, vs, distmx, alg.normalize, alg.endpoints)
end

function _betweenness_centrality(g::AbstractGraph, vs::AbstractVector, distmx::AbstractMatrix, normalize::Bool, endpoints::Bool)
    n_v = nv(g)
    k = length(vs)
    isdir = is_directed(g)

    betweenness = zeros(n_v)
    dstate = Dijkstra(all_paths=true, track_vertices=true)
    for s in vs
        if degree(g, s) > 0  # this might be 1?
            result = shortest_paths(g, s, distmx, dstate)
            if endpoints
                _accumulate_endpoints!(betweenness, result, g, s)
            else
                _accumulate_basic!(betweenness, result, g, s)
            end
        end
    end

    _rescale!(betweenness,
    n_v,
    normalize,
    isdir,
    k)

    return betweenness
end

function _accumulate_basic!(betweenness::Vector{Float64},
    state::DijkstraResult,
    g::AbstractGraph,
    si::Integer)

    n_v = length(state.parents) # this is the ttl number of vertices
    δ = zeros(n_v)
    σ = state.pathcounts
    P = state.predecessors

    # make sure the source index has no parents.
    P[si] = []
    # we need to order the source vertices by decreasing distance for this to work.
    S = reverse(state.closest_vertices) #Replaced sortperm with this
    for w in S
        coeff = (1.0 + δ[w]) / σ[w]
        for v in P[w]
            if v > 0
                δ[v] += (σ[v] * coeff)
            end
        end
        if w != si
            betweenness[w] += δ[w]
        end
    end
    return nothing
end

function _accumulate_endpoints!(betweenness::Vector{Float64},
    state::DijkstraResult,
    g::AbstractGraph,
    si::Integer)

    n_v = nv(g) # this is the ttl number of vertices
    δ = zeros(n_v)
    σ = state.pathcounts
    P = state.predecessors
    v1 = collect(Base.OneTo(n_v))
    v2 = state.dists
    S = reverse(state.closest_vertices)
    s = vertices(g)[si]
    betweenness[s] += length(S) - 1    # 289

    for w in S
        coeff = (1.0 + δ[w]) / σ[w]
        for v in P[w]
            δ[v] += σ[v] * coeff
        end
        if w != si
            betweenness[w] += (δ[w] + 1)
        end
    end
    return nothing
end

function _rescale!(betweenness::Vector{Float64}, n::Integer, normalize::Bool, directed::Bool, k::Integer)
    if normalize
        if n <= 2
            do_scale = false
        else
            do_scale = true
            scale = 1.0 / ((n - 1) * (n - 2))
        end
    else
        if !directed
            do_scale = true
            scale = 1.0 / 2.0
        else
            do_scale = false
        end
    end
    if do_scale
        if k > 0
            scale = scale * n / k
        end
        betweenness .*= scale
    end
    return nothing
end