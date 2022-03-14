defmodule PlankGames.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # {Cluster.Supervisor, [topologies, [name: PlankGames.ClusterSupervisor]]},
      PlankGamesWeb.Telemetry,
      {Phoenix.PubSub, name: PlankGames.PubSub},
      PlankGamesWeb.Endpoint,
      PlankGames.Common.Monitor,
      PlankGames.Stats.Registry,
      PlankGames.TicTacToe,
      PlankGames.ConnectFour,
      PlankGames.Yahtzee
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
