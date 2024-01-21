defmodule PlankGames.Common.LobbyManager do
  def new(lobby_id, type),
    do:
      %PlankGames.Common.LobbyState{:id => lobby_id, :type => type}
      |> new()

  def new(state) do
    new_state =
      %PlankGames.Common.LobbyState{
        state
        | :has_started? => false,
          :has_finished? => false,
          :winner => nil
      }
      |> shuffle_players()

    case Map.get(state, :type) do
      :tic_tac_toe ->
        new_state
        |> Map.put(:game_state, %PlankGames.TicTacToe.State{})
        |> Map.put(:rules, %PlankGames.TicTacToe.Rules{})

      :connect_four ->
        new_state
        |> Map.put(:game_state, %PlankGames.ConnectFour.State{})
        |> Map.put(:rules, %PlankGames.ConnectFour.Rules{})
    end
  end

  def start(state) do
    %PlankGames.Common.LobbyState{
      state
      | :has_started? => true,
        :has_finished? => false,
        :winner => nil
    }
    |> shuffle_players()
  end

  def finish(state) do
    %PlankGames.Common.LobbyState{
      state
      | :has_started? => false,
        :has_finished? => true
    }
  end

  def set_winner(state) do
    %PlankGames.Common.LobbyState{
      state
      | :winner => Map.get(state, :current_player)
    }
  end

  def add_player(state, player_id) do
    case is_player_slot_available?(state) do
      true ->
        case is_player_already_joined?(state, player_id) do
          true ->
            {:already_joined, state}

          false ->
            new_state = state |> _add_player(player_id)

            case can_game_start?(new_state) and new_state.rules.auto_start do
              true -> {:ok, new_state |> start()}
              false -> {:ok, new_state}
            end
        end

      false ->
        {:full, state}
    end
  end

  def remove_player(state, player_id) do
    if Enum.any?(state.players, fn x -> x.id == player_id end) do
      {:ok,
       state
       |> Map.put(:players, Enum.filter(state.players, fn x -> x.id != player_id end))
       |> Map.put(:has_finished?, if(state.rules.end_on_player_leave, do: true, else: false))
       |> Map.put(
         :has_started?,
         if(state.rules.end_on_player_leave, do: false, else: state.has_started?)
       )}
    else
      {:not_player, state}
    end
  end

  def can_game_start?(state), do: Enum.count(state.players) >= state.rules.min_players

  def leave_lobby(state, player_id) do
    if Enum.any?(Map.keys(state.connections)) do
      {:empty,
       %PlankGames.Common.LobbyState{
         state
         | :players => Enum.filter(state.players, fn x -> x.id != player_id end),
           :has_finished? => true
       }}
    else
      case is_player?(state, player_id) do
        true ->
          {:player_left, elem(remove_player(state, player_id), 1)}

        false ->
          {:ok, state}
      end
    end
  end

  def switch_player(state) do
    player_index = Enum.find_index(state.players, fn x -> x.id == state.current_player.id end)

    cond do
      player_index == Enum.count(state.players) - 1 ->
        Map.put(state, :current_player, List.first(state.players))

      true ->
        Map.put(state, :current_player, Enum.at(state.players, player_index + 1))
    end
  end

  def should_close?(state), do: state.connection_count < 1

  def is_joinable?(state, player_id) do
    cond do
      is_player?(state, player_id) ->
        false

      Map.get(state, :has_finished) ->
        true

      Map.get(state, :has_started) ->
        false

      true ->
        true
    end
  end

  def is_player?(state, player_id), do: Enum.any?(state.players, fn x -> x.id == player_id end)

  def connection_join(state, player_id),
    do:
      {:ok,
       Map.put(
         state,
         :connections,
         Map.update(state.connections, player_id, 1, fn count -> count + 1 end)
       )}

  def connection_leave(state, player_id) do
    state =
      Map.put(
        state,
        :connections,
        Map.update(state.connections, player_id, 1, fn count -> count - 1 end)
      )

    if Map.get(state.connections, player_id) < 1 do
      state = Map.put(state, :connections, elem(Map.pop(state.connections, player_id), 1))
      leave_lobby(state, player_id)
    else
      {:ok, state}
    end
  end

  def get_connection_count(state) do
    total = Enum.reduce(state.connections, 0, fn x, acc -> acc + elem(x, 1) end)
    %{total: total, players: Enum.count(Map.keys(state.connections))}
  end

  defp shuffle_players(state) do
    shuffled_players = Enum.shuffle(state.players)

    %PlankGames.Common.LobbyState{
      state
      | :players => shuffled_players,
        :current_player => List.first(shuffled_players)
    }
  end

  defp is_player_slot_available?(state), do: Enum.count(state.players) < state.rules.max_players

  defp is_player_already_joined?(state, player_id),
    do: Enum.any?(state.players, fn x -> x.id == player_id end)

  defp _add_player(state, player_id) do
    {:ok, player_name} = PlankGames.Common.PlayerNameGenerator.generate()

    state
    |> Map.put(
      :players,
      state.players ++
        [
          %{
            :name => player_name,
            :id => player_id
          }
        ]
    )
  end
end
