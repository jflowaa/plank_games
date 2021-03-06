import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :plank_games, PlankGamesWeb.Endpoint,
  http: [port: 4000],
  url: [host: "plank.games", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  code_reloader: false

# Do not print debug messages in production
config :logger, level: :info

# config :libcluster,
#   topologies: [
#     render: [
#       strategy: Cluster.Strategy.Kubernetes.DNS,
#       config: [
#         service: "plank-games-headless-svc",
#         application_name: "plank_games",
#         polling_interval: 3_000
#       ]
#     ]
#   ]
