defmodule PlankGames.ConnectFour do
  use Supervisor

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: ConnectFour.Supervisor)

  def init(_args) do
    children = [
      {DynamicSupervisor, name: PlankGames.ConnectFour.LobbySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: PlankGames.ConnectFour.LobbyRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id),
    do:
      DynamicSupervisor.start_child(
        PlankGames.ConnectFour.LobbySupervisor,
        {PlankGames.ConnectFour.Server, lobby_id: lobby_id}
      )
end
