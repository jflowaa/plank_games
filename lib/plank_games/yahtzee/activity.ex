defmodule Yahtzee.Activity do
  use GenServer
  require Logger

  def lookup(), do: GenServer.call(GenServer.whereis({:global, __MODULE__}), :get)

  def refresh(), do: GenServer.call(GenServer.whereis({:global, __MODULE__}), :refresh)

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_), do: {:ok, get_lobbies()}

  def handle_call(:get, _from, state), do: {:reply, state, get_lobbies()}

  def handle_call(:refresh, _from, state), do: {:reply, state, get_lobbies()}

  defp get_lobbies() do
    children = Supervisor.which_children(Yahtzee.LobbySupervisor)

    Enum.reduce(children, %{}, fn child, state ->
      lobby_state = :sys.get_state(elem(child, 1))

      Map.put(
        state,
        lobby_state.id,
        lobby_state.connection_count
      )
    end)
  end
end
