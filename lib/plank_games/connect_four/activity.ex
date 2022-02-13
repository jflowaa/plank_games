defmodule ConnectFour.Activity do
  use GenServer
  require Logger

  def lookup(), do: GenServer.call(via_tuple(), :get)

  def refresh(lobby_id), do: GenServer.call(via_tuple(), {:refresh, lobby_id})

  def refresh(), do: GenServer.call(via_tuple(), :refresh)

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: via_tuple()) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_), do: {:ok, get_lobbies()}

  def handle_call(:get, _from, state), do: {:reply, state, get_lobbies()}

  def handle_call(:refresh, _from, state), do: {:reply, state, get_lobbies()}

  def handle_call({:refresh, lobby_id}, _from, state),
    do:
      {:reply, state,
       Map.put(
         state,
         lobby_id,
         ConnectFour.Presence.list("ConnectFour.Lobby_#{lobby_id}") |> map_size
       )}

  defp via_tuple(),
    do: {:via, Horde.Registry, {ConnectFour.Registry, __MODULE__}}

  defp get_lobbies() do
    children = Supervisor.which_children(ConnectFour.GameSupervisor)

    Enum.reduce(children, %{}, fn child, state ->
      lobby_state = :sys.get_state(elem(child, 1))

      Map.put(
        state,
        lobby_state.id,
        ConnectFour.Presence.list("#{inspect(ConnectFour.Lobby)}_#{lobby_state.id}") |> map_size
      )
    end)
  end
end