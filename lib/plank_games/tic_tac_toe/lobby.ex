defmodule TicTacToe.Lobby do
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

  def new(lobby_id, client_id), do: GenServer.call(via_tuple(lobby_id), {:new, client_id})

  def remove_client(lobby_id, client_id),
    do: GenServer.call(via_tuple(lobby_id), {:remove_client, client_id})

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

    # case Redix.command(:redix, ["GET", Keyword.get(args, :lobby_id)]) do
    #   {:ok, x} when not is_nil(x) ->
    #     {:ok, :erlang.binary_to_term(x)}

    #   _ ->
    #  {:ok, Common.LobbyState.new(Keyword.get(args, :lobby_id), TicTacToe)}
    # end

    {:ok, Common.LobbyState.new(Keyword.get(args, :lobby_id), :tictactoe)}
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
      Enum.count(state.players) >= 2 ->
        {:reply, :full, state}

      Enum.any?(state.players, fn x -> x == player_id end) ->
        {:reply, :already_joined, state}

      true ->
        state = Map.put(state, :players, state.players ++ [player_id])

        case Enum.count(state.players) do
          2 ->
            {:reply, :ok, state |> Common.LobbyState.start()}

          _ ->
            {:reply, :ok, state}
        end
    end
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, position}, _from, state) do
    result = TicTacToe.State.move(Map.get(state, :game_state), position)

    case elem(result, 0) do
      :ok ->
        case TicTacToe.State.is_won(elem(result, 1)) do
          :winner ->
            {:reply, :ok,
             %Common.LobbyState{
               state
               | :game_state => elem(result, 1),
                 :has_finished => true,
                 :winner => state.current_player
             }}

          :tie ->
            {:reply, :ok,
             %Common.LobbyState{
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

  def handle_call({:remove_client, client_id}, _from, state) do
    result = Common.LobbyState.remove_client(state, client_id)

    if state.client_count == 1, do: Process.send_after(self(), :close, 10000)

    {:reply, elem(result, 0),
     Map.put(elem(result, 1), :client_count, Map.get(state, :client_count) - 1)}
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
    do: {:via, Horde.Registry, {TicTacToe.Registry, "lobby_#{lobby_id}"}}

  defp switch_player(state),
    do:
      Map.put(
        Common.LobbyState.switch_player(state),
        :game_state,
        TicTacToe.State.switch_token(Map.get(state, :game_state))
      )
end
