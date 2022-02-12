defmodule PlankGames.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # topologies = Application.get_env(:libcluster, :topologies) || []
    redis_config = Application.get_env(:redix, :config) || raise "No Redis configuration provided"

    children = [
      # {Cluster.Supervisor, [topologies, [name: PlankGames.ClusterSupervisor]]},
      {Redix, name: :redix, host: Keyword.get(redis_config, :host)},
      # Start the Telemetry supervisor
      PlankGamesWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PlankGames.PubSub},
      # Start the Endpoint (http/https)
      PlankGamesWeb.Endpoint,
      # Start a worker by calling: PlankGames.Worker.start_link(arg)
      # {PlankGames.Worker, arg}
      TicTacToe,
      TicTacToe.Presence,
      ConnectFour,
      ConnectFour.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlankGames.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PlankGamesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
