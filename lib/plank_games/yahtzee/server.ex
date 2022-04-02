defmodule PlankGames.Yahtzee.Server do
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
    Process.send_after(self(), :close, 10000)
    {:ok, PlankGames.Common.LobbyState.new(Keyword.get(args, :lobby_id), :yahtzee)}
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
      Enum.any?(state.players, fn x -> x.id == player_id end) ->
        {:reply, :already_joined, state}

      true ->
        {:reply, :ok,
         state
         |> PlankGames.Common.LobbyState.add_player(player_id)
         |> Map.put(
           :game_state,
           PlankGames.Yahtzee.State.add_scorecard(state.game_state, player_id)
         )}
    end
  end

  def handle_call({:leave_game, player_id}, _from, state) do
    result = PlankGames.Common.LobbyState.remove_player(state, player_id)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call(:start, _from, state),
    do: {:reply, :ok, PlankGames.Common.LobbyState.start(state)}

  def handle_call({:roll, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:roll, player_id}, _from, state) when state.current_player.id != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:roll, _}, _from, state) do
    result = PlankGames.Yahtzee.State.roll_dice(state.game_state)

    case elem(result, 0) do
      :ok ->
        {:reply, elem(result, 0), Map.put(state, :game_state, elem(result, 1))}

      _ ->
        {:reply, elem(result, 0), state}
    end
  end

  def handle_call({:hold_die, _, _}, _from, state)
      when not state.has_started or state.has_finished,
      do: {:reply, :not_started, state}

  def handle_call({:hold_die, player_id, _}, _from, state)
      when state.current_player.id != player_id,
      do: {:reply, :not_turn, state}

  def handle_call({:hold_die, _, die}, _from, state) when die < 1 or die > 5,
    do: {:reply, :invalid_die, state}

  def handle_call({:hold_die, _, die}, _from, state),
    do:
      {:reply, :ok,
       Map.put(state, :game_state, PlankGames.Yahtzee.State.hold_die(state.game_state, die))}

  def handle_call({:release_die, _, _}, _from, state)
      when not state.has_started or state.has_finished,
      do: {:reply, :not_started, state}

  def handle_call({:release_die, player_id, _}, _from, state)
      when state.current_player.id != player_id,
      do: {:reply, :not_turn, state}

  def handle_call({:release_die, _, die}, _from, state) when die < 1 or die > 5,
    do: {:reply, :invalid_die, state}

  def handle_call({:release_die, _, die}, _from, state),
    do:
      {:reply, :ok,
       Map.put(state, :game_state, PlankGames.Yahtzee.State.release_die(state.game_state, die))}

  def handle_call({:end_turn, player_id, category}, _from, state) do
    result = PlankGames.Yahtzee.State.end_turn(state.game_state, player_id, category)

    case elem(result, 0) do
      :ok ->
        {:reply, elem(result, 0),
         Map.put(
           state,
           :game_state,
           PlankGames.Yahtzee.State.compute_player_totals(elem(result, 1))
         )
         |> PlankGames.Common.LobbyState.switch_player()}

      _ ->
        {:reply, elem(result, 0), Map.put(state, :game_state, elem(result, 1))}
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

  def handle_info(:close, state), do: handle_call(:close, nil, state)

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.Yahtzee.LobbyRegistry, "lobby_#{lobby_id}"}}
end
