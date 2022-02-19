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

  def new(lobby_id), do: GenServer.call(via_tuple(lobby_id), :new)

  def add_client(lobby_id, client_id),
    do: GenServer.call(via_tuple(lobby_id), {:add_client, client_id})

  def remove_client(lobby_id, client_id),
    do: GenServer.call(via_tuple(lobby_id), {:remove_client, client_id})

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

    case Redix.command(:redix, ["GET", Keyword.get(args, :lobby_id)]) do
      {:ok, x} when not is_nil(x) ->
        {:ok, :erlang.binary_to_term(x)}

      _ ->
        {:ok, %TicTacToe.LobbyState{:id => Keyword.get(args, :lobby_id)}}
    end
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call(:new, _from, state) do
    if state.has_finished do
      {:reply, :ok,
       %TicTacToe.LobbyState{
         :id => state.id,
         :player_one => state.player_one,
         :player_two => state.player_two,
         :current_player => state.player_one,
         :current_token => "x",
         :has_started => true
       }}
    else
      {:reply, :not_finished, state}
    end
  end

  def handle_call({:join, player_id}, _from, state) do
    case state do
      %{:player_one => val} when is_nil(val) ->
        if player_id == state.player_two do
          {:reply, :already_joined, state}
        else
          {:reply, :ok, Map.put(state, :player_one, player_id)}
        end

      %{:player_two => val} when is_nil(val) ->
        if player_id == state.player_one do
          {:reply, :already_joined, state}
        else
          {:reply, :ok,
           %TicTacToe.LobbyState{
             state
             | :player_two => player_id,
               :current_player => state.player_one,
               :current_token => "x",
               :has_started => true
           }}
        end

      _ ->
        {:reply, :full, state}
    end
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, position}, _from, state) do
    if Enum.at(state.board, position) == "" do
      state = update_board(state, position) |> is_over

      if state.has_finished do
        {:reply, :ok, state}
      else
        {:reply, :ok, state |> switch_player}
      end
    else
      {:reply, :invalid_move, state}
    end
  end

  def handle_call({:remove_client, client_id}, _from, state) do
    case client_id do
      x when x == state.player_one ->
        {:reply, :player_left,
         %TicTacToe.LobbyState{state | :player_one => nil, :has_started => false}}

      x when x == state.player_two ->
        {:reply, :player_left,
         %TicTacToe.LobbyState{state | :player_two => nil, :has_started => false}}

      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_info(:close, state) do
    cond do
      is_nil(Map.get(state, :player_one)) and is_nil(Map.get(state, :player_two)) ->
        {:stop, :normal, state}

      true ->
        {:noreply, state}
    end
  end

  defp via_tuple(lobby_id),
    do: {:via, Horde.Registry, {TicTacToe.Registry, "lobby_#{lobby_id}"}}

  defp switch_player(state) do
    case state.current_token do
      "x" ->
        %TicTacToe.LobbyState{state | :current_token => "o", :current_player => state.player_two}

      _ ->
        %TicTacToe.LobbyState{state | :current_token => "x", :current_player => state.player_one}
    end
  end

  defp update_board(state, position),
    do: Map.put(state, :board, List.replace_at(state.board, position, state.current_token))

  defp is_over(state) do
    case state.board do
      [x, x, x, _, _, _, _, _, _] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [_, _, _, x, x, x, _, _, _] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [_, _, _, _, _, _, x, x, x] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [x, _, _, x, _, _, x, _, _] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [_, x, _, _, x, _, _, x, _] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [_, _, x, _, _, x, _, _, x] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [x, _, _, _, x, _, _, _, x] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [_, _, x, _, x, _, x, _, _] when x == state.current_token ->
        %TicTacToe.LobbyState{state | :winner => state.current_player, :has_finished => true}

      [x, x, x, x, x, x, x, x, x] when x != "" ->
        %TicTacToe.LobbyState{state | :has_finished => true}

      _ ->
        case Enum.all?(state.board, &(&1 != "")) do
          true -> %TicTacToe.LobbyState{state | :has_finished => true}
          false -> state
        end
    end
  end
end
