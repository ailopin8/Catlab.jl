module CatlabWebApp

using Catlab.Graphs.BasicGraphs: Graph, add_edge!, nv, ne, src, tgt
using HTTP
using JSON3

export handle_request, serve

const INDEX_PATH = normpath(joinpath(@__DIR__, "..", "public", "index.html"))

struct ApiError <: Exception
  message::String
  status::Int
end

json_response(status::Integer, payload) = HTTP.Response(status, ["Content-Type" => "application/json"], JSON3.write(payload))

json_get(x, key::Symbol, default=nothing) = haskey(x, key) ? x[key] : default

function parse_graph_payload(body)
  data = JSON3.read(body)

  vertices = json_get(data, :vertices, nothing)
  if !(vertices isa Integer) || vertices < 0
    throw(ApiError("`vertices` must be a non-negative integer", 400))
  end

  raw_edges = json_get(data, :edges, Any[])
  if !(raw_edges isa AbstractVector)
    throw(ApiError("`edges` must be an array", 400))
  end

  graph = Graph(vertices)
  for (i, edge) in enumerate(raw_edges)
    if !(edge isa AbstractDict)
      throw(ApiError("edge $(i) must be an object with `src` and `tgt`", 400))
    end

    s = json_get(edge, :src, nothing)
    t = json_get(edge, :tgt, nothing)
    if !(s isa Integer) || !(t isa Integer)
      throw(ApiError("edge $(i) must use integer `src` and `tgt`", 400))
    end
    if s < 1 || s > vertices || t < 1 || t > vertices
      throw(ApiError("edge $(i) references a vertex outside 1:$(vertices)", 400))
    end

    add_edge!(graph, s, t)
  end

  graph
end

function graph_dict(graph::Graph)
  Dict(
    "vertices" => [Dict("id" => v) for v in 1:nv(graph)],
    "edges" => [Dict("id" => i, "src" => s, "tgt" => t) for (i, (s, t)) in enumerate(zip(src(graph), tgt(graph)))],
  )
end

function graph_metrics(graph::Graph)
  out_degrees = zeros(Int, nv(graph))
  in_degrees = zeros(Int, nv(graph))

  for s in src(graph)
    out_degrees[s] += 1
  end
  for t in tgt(graph)
    in_degrees[t] += 1
  end

  Dict(
    "vertex_count" => nv(graph),
    "edge_count" => ne(graph),
    "out_degrees" => out_degrees,
    "in_degrees" => in_degrees,
  )
end

function graph_dot(graph::Graph)
  io = IOBuffer()
  println(io, "digraph CatlabGraph {")
  for v in 1:nv(graph)
    println(io, "  v", v, " [label=\"", v, "\"];")
  end
  for (i, (s, t)) in enumerate(zip(src(graph), tgt(graph)))
    println(io, "  v", s, " -> v", t, " [label=\"e", i, "\"];")
  end
  println(io, "}")
  String(take!(io))
end

function api_dispatch(path::AbstractString, body)
  graph = parse_graph_payload(body)

  if path == "/api/parse"
    return json_response(200, Dict("graph" => graph_dict(graph)))
  elseif path == "/api/compute"
    return json_response(200, Dict("metrics" => graph_metrics(graph)))
  elseif path == "/api/render"
    return json_response(200, Dict("dot" => graph_dot(graph)))
  else
    return json_response(404, Dict("error" => "Not Found"))
  end
end

function handle_request(req::HTTP.Request)
  try
    method = String(req.method)
    path = String(req.target)

    if method == "GET" && path == "/"
      return HTTP.Response(200, ["Content-Type" => "text/html; charset=utf-8"], read(INDEX_PATH, String))
    elseif method == "GET" && path == "/api/health"
      return json_response(200, Dict("status" => "ok"))
    elseif method == "POST"
      return api_dispatch(path, req.body)
    else
      return json_response(404, Dict("error" => "Not Found"))
    end
  catch err
    if err isa ApiError
      return json_response(err.status, Dict("error" => err.message))
    end
    return json_response(500, Dict("error" => "Internal server error"))
  end
end

function serve(; host::AbstractString="127.0.0.1", port::Integer=8080, verbose::Bool=true)
  HTTP.serve(handle_request, host, port; verbose=verbose)
end

end
