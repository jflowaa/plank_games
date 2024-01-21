defmodule PlankGames.TicTacToe do
  use Supervisor

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: TicTacToe.Supervisor)

  def init(_args) do
    children = [
      {DynamicSupervisor, name: PlankGames.TicTacToe.LobbySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: PlankGames.TicTacToe.LobbyRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id),
    do:
      DynamicSupervisor.start_child(
        PlankGames.TicTacToe.LobbySupervisor,
        {PlankGames.TicTacToe.Server, lobby_id: lobby_id}
      )
end
