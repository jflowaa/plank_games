defmodule ConnectFour do
  use Supervisor

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 10_000
    }
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: ConnectFour.Supervisor)
  end

  def init(_args) do
    children = [
      {Horde.DynamicSupervisor,
       name: ConnectFour.GameSupervisor, strategy: :one_for_one, members: :auto, shutdown: 10_000},
      {Horde.Registry,
       name: ConnectFour.Registry, keys: :unique, members: :auto, shutdown: 10_000},
      {ConnectFour.Activity, name: ConnectFour.Activity, strategy: :one_for_one, shutdown: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id) do
    Horde.DynamicSupervisor.start_child(
      ConnectFour.GameSupervisor,
      {ConnectFour.Lobby, lobby_id: lobby_id, lobby_type: ConnectFour}
    )
  end
end
