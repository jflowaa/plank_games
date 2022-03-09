defmodule ConnectFour do
  use Supervisor

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: ConnectFour.Supervisor)
  end

  def init(_args) do
    children = [
      {DynamicSupervisor, name: ConnectFour.LobbySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: ConnectFour.LobbyRegistry},
      {Registry, keys: :unique, name: ConnectFour.ActivityRegistry},
      {ConnectFour.Activity, name: ConnectFour.Activity, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id) do
    DynamicSupervisor.start_child(
      ConnectFour.LobbySupervisor,
      {ConnectFour.Lobby, lobby_id: lobby_id, lobby_type: ConnectFour}
    )
  end
end
