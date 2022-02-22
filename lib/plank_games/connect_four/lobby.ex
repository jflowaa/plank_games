defmodule ConnectFour.Lobby do
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
    {:ok, Common.LobbyState.new(Keyword.get(args, :lobby_id), :connectfour)}
  end

  def terminate(_, state) do
    if state.has_started do
      Redix.noreply_command(:redix, [
        "SET",
        Map.get(state, :id),
        :erlang.term_to_binary(state)
      ])
    end
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
          {:reply, :ok, Map.put(state, :player_two, player_id) |> Common.LobbyState.start()}
        end

      _ ->
        {:reply, :full, state}
    end
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, column}, _from, state) do
    result = ConnectFour.State.drop_checker(Map.get(state, :game_state), column)

    case elem(result, 0) do
      :ok ->
        case ConnectFour.State.is_over(elem(result, 1)) do
          :over ->
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
    do: {:via, Horde.Registry, {ConnectFour.Registry, "lobby_#{lobby_id}"}}

  defp switch_player(state),
    do:
      Map.put(
        Common.LobbyState.switch_player(state),
        :game_state,
        ConnectFour.State.switch_token(Map.get(state, :game_state))
      )
end
