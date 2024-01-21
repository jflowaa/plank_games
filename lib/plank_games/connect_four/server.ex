defmodule PlankGames.ConnectFour.Server do
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
    {:ok, PlankGames.Common.LobbyManager.new(Keyword.get(args, :lobby_id), :connect_four)}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call({:new, player_id}, _from, state) do
    cond do
      not PlankGames.Common.LobbyManager.is_player?(state, player_id) ->
        {:reply, :not_player, state}

      state.has_finished? ->
        case PlankGames.Common.LobbyManager.can_game_start?(state) and state.rules.auto_start do
          true ->
            {:reply, :ok,
             state
             |> PlankGames.Common.LobbyManager.new()
             |> PlankGames.Common.LobbyManager.start()}

          false ->
            {:reply, :ok, state |> PlankGames.Common.LobbyManager.new()}
        end

      true ->
        {:reply, :not_finished, state}
    end
  end

  def handle_call({:join, player_id}, _from, state) do
    {result, new_state} = PlankGames.Common.LobbyManager.add_player(state, player_id)
    {:reply, result, new_state}
  end

  def handle_call({:leave_game, player_id}, _from, state) do
    result = PlankGames.Common.LobbyManager.remove_player(state, player_id)

    {:reply, elem(result, 0), elem(result, 1)}
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started? or state.has_finished?,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player.id != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, column}, _from, state) do
    {result, game_state} = PlankGames.ConnectFour.State.move(Map.get(state, :game_state), column)

    if result == :ok do
      case PlankGames.ConnectFour.State.is_over?(game_state) do
        :winner ->
          {:reply, result,
           state
           |> Map.put(:game_state, game_state)
           |> PlankGames.Common.LobbyManager.finish()
           |> PlankGames.Common.LobbyManager.set_winner()}

        _ ->
          {:reply, result,
           state
           |> Map.put(:game_state, game_state |> PlankGames.ConnectFour.State.switch_token())
           |> PlankGames.Common.LobbyManager.switch_player()}
      end
    else
      {:reply, result, state}
    end
  end

  def handle_call({:leave, player_id}, _from, state) do
    {result, new_state} = PlankGames.Common.LobbyManager.remove_player(state, player_id)

    {:reply, result, new_state}
  end

  def handle_call(:join_lobby, _from, state),
    do: {:reply, :ok, Map.put(state, :connection_count, Map.get(state, :connection_count) + 1)}

  def handle_call(:close_lobby, _from, state) do
    {:stop, :normal, state, state}
  end

  def handle_info({:EXIT, _, :shutdown}, state) do
    Logger.info("shutting down lobby #{state.id} due to application shutdown")
    {:noreply, state}
  end

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.ConnectFour.LobbyRegistry, "lobby_#{lobby_id}"}}
end
