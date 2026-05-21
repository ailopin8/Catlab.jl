#!/usr/bin/env julia

using CatlabWebApp

host = get(ENV, "CATLAB_WEBAPP_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "CATLAB_WEBAPP_PORT", "8080"))

println("Starting Catlab webapp at http://$(host):$(port)")
serve(; host=host, port=port)
