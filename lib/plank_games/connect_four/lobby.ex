defmodule PlankGames.ConnectFour.Lobby do
  use GenServer, restart: :transient
  require Logger

  def lookup(lobby_id) do
    try do
      GenServer.call(via_tuple(lobby_id), :get)
    catch
      :exit, _ ->
        Logger.info("Lobby not found, going to retry after 1 second")
        Process.sleep(1000)
        GenServer.call(via_tuple(lobby_id), :get)
    end
  end

  def join(lobby_id, player_id), do: GenServer.call(via_tuple(lobby_id), {:join, player_id})

  def move(lobby_id, player_id, position),
    do: GenServer.call(via_tuple(lobby_id), {:move, player_id, position})

  def new(lobby_id, player_id), do: GenServer.call(via_tuple(lobby_id), {:new, player_id})

  def remove_player(lobby_id, player_id),
    do: GenServer.call(via_tuple(lobby_id), {:remove_player, player_id})

  def remove_player(lobby_id),
    do: GenServer.call(via_tuple(lobby_id), :remove_player)

  def add_player(lobby_id), do: GenServer.call(via_tuple(lobby_id), :add_player)

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: via_tuple(Keyword.get(opts, :lobby_id))) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(args) do
    Process.flag(:trap_exit, true)
    {:ok, PlankGames.Common.LobbyState.new(Keyword.get(args, :lobby_id), :connectfour)}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call({:new, player_id}, _from, state) do
    cond do
      not PlankGames.Common.LobbyState.is_player?(state, player_id) ->
        {:reply, :not_player, state}

      state.has_finished ->
        {:reply, :ok, PlankGames.Common.LobbyState.new(state)}

      true ->
        {:reply, :not_finished, state}
    end
  end

  def handle_call({:join, player_id}, _from, state) do
    cond do
      Enum.count(state.players) >= 2 ->
        {:reply, :full, state}

      Enum.any?(state.players, fn x -> x.id == player_id end) ->
        {:reply, :already_joined, state}

      true ->
        state = PlankGames.Common.LobbyState.add_player(state, player_id)

        case Enum.count(state.players) do
          2 ->
            {:reply, :ok, state |> PlankGames.Common.LobbyState.start()}

          _ ->
            {:reply, :ok, state}
        end
    end
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player.id != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, column}, _from, state) do
    result = PlankGames.ConnectFour.State.drop_checker(Map.get(state, :game_state), column)

    case elem(result, 0) do
      :ok ->
        case PlankGames.ConnectFour.State.is_over(elem(result, 1)) do
          :over ->
            {:reply, :ok,
             %PlankGames.Common.LobbyState{
               state
               | :game_state => elem(result, 1),
                 :has_finished => true,
                 :winner => state.current_player.id
             }}

          :tie ->
            {:reply, :ok,
             %PlankGames.Common.LobbyState{
               state
               | :game_state => elem(result, 1),
                 :has_finished => true,
                 :winner => nil
             }}

          _ ->
            {:reply, elem(result, 0),
             Map.put(state, :game_state, elem(result, 1)) |> switch_player}
        end

      _ ->
        {:reply, elem(result, 0), state}
    end
  end

  def handle_call({:remove_player, player_id}, _from, state) do
    result = PlankGames.Common.LobbyState.remove_player(state, player_id)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call(:remove_player, _from, state) do
    if state.connection_count <= 1, do: Process.send_after(self(), :close, 10000)

    {:reply, :ok, Map.put(state, :connection_count, Map.get(state, :connection_count) - 1)}
  end

  def handle_call(:add_player, _from, state),
    do: {:reply, :ok, Map.put(state, :connection_count, Map.get(state, :connection_count) + 1)}

  def handle_info(:close, state) do
    case PlankGames.Common.LobbyState.should_close?(state) do
      true ->
        {:stop, :normal, state}

      false ->
        {:noreply, state}
    end
  end

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.ConnectFour.LobbyRegistry, "lobby_#{lobby_id}"}}

  defp switch_player(state),
    do:
      Map.put(
        PlankGames.Common.LobbyState.switch_player(state),
        :game_state,
        PlankGames.ConnectFour.State.switch_token(Map.get(state, :game_state))
      )
end
