using Test
using HTTP
using JSON3
using CatlabWebApp

function parse_json_response(resp::HTTP.Response)
  JSON3.read(String(resp.body))
end

@testset "CatlabWebApp API" begin
  @testset "Health endpoint" begin
    resp = handle_request(HTTP.Request("GET", "/api/health"))
    @test resp.status == 200
    body = parse_json_response(resp)
    @test body[:status] == "ok"
  end

  payload = Dict(
    "vertices" => 3,
    "edges" => [
      Dict("src" => 1, "tgt" => 2),
      Dict("src" => 2, "tgt" => 3),
      Dict("src" => 1, "tgt" => 3),
    ],
  )

  @testset "Parse endpoint" begin
    req = HTTP.Request("POST", "/api/parse", ["Content-Type" => "application/json"], JSON3.write(payload))
    resp = handle_request(req)

    @test resp.status == 200
    body = parse_json_response(resp)
    @test length(body[:graph][:vertices]) == 3
    @test length(body[:graph][:edges]) == 3
  end

  @testset "Compute endpoint" begin
    req = HTTP.Request("POST", "/api/compute", ["Content-Type" => "application/json"], JSON3.write(payload))
    resp = handle_request(req)

    @test resp.status == 200
    body = parse_json_response(resp)
    metrics = body[:metrics]
    @test metrics[:vertex_count] == 3
    @test metrics[:edge_count] == 3
    @test copy(metrics[:out_degrees]) == [2, 1, 0]
    @test copy(metrics[:in_degrees]) == [0, 1, 2]
  end

  @testset "Render endpoint" begin
    req = HTTP.Request("POST", "/api/render", ["Content-Type" => "application/json"], JSON3.write(payload))
    resp = handle_request(req)

    @test resp.status == 200
    body = parse_json_response(resp)
    @test occursin("digraph CatlabGraph", String(body[:dot]))
    @test occursin("v1 -> v2", String(body[:dot]))
  end

  @testset "Validation error" begin
    bad_payload = Dict("vertices" => 2, "edges" => [Dict("src" => 1, "tgt" => 3)])
    req = HTTP.Request("POST", "/api/compute", ["Content-Type" => "application/json"], JSON3.write(bad_payload))
    resp = handle_request(req)

    @test resp.status == 400
    body = parse_json_response(resp)
    @test occursin("outside", String(body[:error]))
  end
end
