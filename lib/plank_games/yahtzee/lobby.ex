defmodule Yahtzee.Lobby do
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

  def new(lobby_id, client_id), do: GenServer.call(via_tuple(lobby_id), {:new, client_id})

  def join(lobby_id, player_id), do: GenServer.call(via_tuple(lobby_id), {:join, player_id})

  def start(lobby_id), do: GenServer.call(via_tuple(lobby_id), :start)

  def roll(lobby_id, player_id),
    do: GenServer.call(via_tuple(lobby_id), {:roll, player_id})

  def hold_die(lobby_id, player_id, die),
    do: GenServer.call(via_tuple(lobby_id), {:hold_die, player_id, die})

  def release_die(lobby_id, player_id, die),
    do: GenServer.call(via_tuple(lobby_id), {:release_die, player_id, die})

  def end_turn(lobby_id, player_id, category),
    do: GenServer.call(via_tuple(lobby_id), {:end_turn, player_id, category})

  def remove_player(lobby_id, client_id),
    do: GenServer.call(via_tuple(lobby_id), {:remove_player, client_id})

  def remove_client(lobby_id),
    do: GenServer.call(via_tuple(lobby_id), :remove_client)

  def add_client(lobby_id), do: GenServer.call(via_tuple(lobby_id), :add_client)

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
    {:ok, Common.LobbyState.new(Keyword.get(args, :lobby_id), :yahtzee)}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call({:new, client_id}, _from, state) do
    cond do
      not Common.LobbyState.is_player?(state, client_id) ->
        {:reply, :not_player, state}

      state.has_finished ->
        {:reply, :ok, Common.LobbyState.new(state)}

      true ->
        {:reply, :not_finished, state}
    end
  end

  def handle_call({:join, player_id}, _from, state) do
    cond do
      Enum.any?(state.players, fn x -> x == player_id end) ->
        {:reply, :already_joined, state}

      true ->
        {:reply, :ok,
         state
         |> Map.put(:players, state.players ++ [player_id])
         |> Map.put(:game_state, Yahtzee.State.add_player(state.game_state, player_id))}
    end
  end

  def handle_call(:start, _from, state), do: {:reply, :ok, state |> Common.LobbyState.start()}

  def handle_call({:roll, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:roll, player_id}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:roll, _}, _from, state) do
    result = Yahtzee.State.roll_dice(state.game_state)

    case elem(result, 0) do
      :ok ->
        {:reply, elem(result, 0),
         Map.put(state, :game_state, elem(result, 1)) |> Common.LobbyState.switch_player()}

      _ ->
        {:reply, elem(result, 0), state}
    end
  end

  def handle_call({:hold_die, _, _}, _from, state)
      when not state.has_started or state.has_finished,
      do: {:reply, :not_started, state}

  def handle_call({:hold_die, player_id, _}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:hold_die, _, die}, _from, state) when die < 1 or die > 5,
    do: {:reply, :invalid_die, state}

  def handle_call({:hold_die, _, die}, _from, state),
    do: {:reply, :ok, Map.put(state, :game_state, Yahtzee.State.hold_die(state.game_state, die))}

  def handle_call({:relase_die, _, _}, _from, state)
      when not state.has_started or state.has_finished,
      do: {:reply, :not_started, state}

  def handle_call({:relase_die, player_id, _}, _from, state)
      when state.current_player != player_id,
      do: {:reply, :not_turn, state}

  def handle_call({:relase_die, _, die}, _from, state) when die < 1 or die > 5,
    do: {:reply, :invalid_die, state}

  def handle_call({:relase_die, _, die}, _from, state),
    do:
      {:reply, :ok, Map.put(state, :game_state, Yahtzee.State.release_die(state.game_state, die))}

  def handle_call({:end_turn, player_id, category}, _from, state) do
    result = Yahtzee.State.end_turn(state.scorecard, player_id, category)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call({:remove_player, player_id}, _from, state) do
    result = Common.LobbyState.remove_client(state, player_id)

    case elem(result, 0) do
      :player_left ->
        {:reply, :player_left,
         elem(result, 1)
         |> Map.put(:game_state, Yahtzee.State.remove_player(state.game_state, player_id))}

      _ ->
        {:reply, elem(result, 0), elem(result, 1)}
    end
  end

  def handle_call(:remove_client, _from, state) do
    if state.client_count == 1, do: Process.send_after(self(), :close, 10000)

    {:reply, :ok, Map.put(state, :client_count, Map.get(state, :client_count) - 1)}
  end

  def handle_call(:add_client, _from, state),
    do: {:reply, :ok, Map.put(state, :client_count, Map.get(state, :client_count) + 1)}

  def handle_info(:close, state) do
    case Common.LobbyState.should_close?(state) do
      true ->
        {:stop, :normal, state}

      false ->
        {:noreply, state}
    end
  end

  defp via_tuple(lobby_id),
    do: {:via, Horde.Registry, {Yahtzee.Registry, "lobby_#{lobby_id}"}}
end
