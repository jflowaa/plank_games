defmodule PlankGames.TicTacToe.Server do
  use GenServer, restart: :transient
  require Logger

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
    {:ok, PlankGames.Common.LobbyState.new(Keyword.get(args, :lobby_id), :tictactoe)}
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

  def handle_call({:join_game, player_id}, _from, state) do
    cond do
      Enum.count(state.players) >= 2 ->
        {:reply, :full, state}

      Enum.any?(state.players, fn x -> x.id == player_id end) ->
        {:reply, :already_joined, state}

      true ->
        state = PlankGames.Common.LobbyState.add_player(state, player_id)

        case Enum.count(state.players) do
          2 ->
            {:reply, :ok, PlankGames.Common.LobbyState.start(state)}

          _ ->
            {:reply, :ok, state}
        end
    end
  end

  def handle_call({:leave_game, player_id}, _from, state) do
    result = PlankGames.Common.LobbyState.remove_player(state, player_id)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player.id != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, position}, _from, state) do
    result = PlankGames.TicTacToe.State.move(Map.get(state, :game_state), position)

    case elem(result, 0) do
      :ok ->
        case PlankGames.TicTacToe.State.is_won(elem(result, 1)) do
          :winner ->
            {:reply, :ok,
             %PlankGames.Common.LobbyState{
               state
               | :game_state => elem(result, 1),
                 :has_finished => true,
                 :winner => state.current_player
             }}

          :tie ->
            {:reply, :ok,
             %PlankGames.Common.LobbyState{
               state
               | :game_state => elem(result, 1),
                 :has_finished => true
             }}

          _ ->
            {:reply, :ok, Map.put(state, :game_state, elem(result, 1)) |> switch_player()}
        end

      _ ->
        {:reply, elem(result, 0), state}
    end
  end

  def handle_call({:leave_lobby, player_id}, _from, state) do
    result = PlankGames.Common.LobbyState.leave_lobby(state, player_id)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call(:join_lobby, _from, state),
    do: {:reply, :ok, Map.put(state, :connection_count, Map.get(state, :connection_count) + 1)}

  def handle_call(:close, _from, state) do
    case PlankGames.Common.LobbyState.should_close?(state) do
      true ->
        {:stop, :normal, state, state}

      false ->
        {:noreply, state}
    end
  end

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.TicTacToe.LobbyRegistry, "lobby_#{lobby_id}"}}

  defp switch_player(state),
    do:
      Map.put(
        PlankGames.Common.LobbyState.switch_player(state),
        :game_state,
        PlankGames.TicTacToe.State.switch_token(Map.get(state, :game_state))
      )
end
