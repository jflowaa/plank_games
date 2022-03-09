defmodule Yahtzee do
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
    Supervisor.start_link(__MODULE__, args, name: Yahtzee.Supervisor)
  end

  def init(_args) do
    children = [
      {DynamicSupervisor, name: Yahtzee.LobbySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Yahtzee.LobbyRegistry},
      {Registry, keys: :unique, name: Yahtzee.ActivityRegistry},
      {Yahtzee.Activity, name: Yahtzee.Activity, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id) do
    DynamicSupervisor.start_child(
      Yahtzee.LobbySupervisor,
      {Yahtzee.Lobby, lobby_id: lobby_id}
    )
  end
end
