defmodule PlankGames.Common.LobbyState do
  defstruct [
    :id,
    :type,
    :current_player,
    :winner,
    :game_state,
    players: [],
    has_started: false,
    has_finished: false,
    connection_count: 0
  ]

  def new(lobby_id, type),
    do:
      %PlankGames.Common.LobbyState{:id => lobby_id, :type => type}
      |> PlankGames.Common.LobbyState.new()

  def new(state) do
    new_state =
      %PlankGames.Common.LobbyState{
        state
        | :has_started => false,
          :has_finished => false,
          :winner => nil
      }
      |> shuffle_players()

    case Map.get(state, :type) do
      :tictactoe -> Map.put(new_state, :game_state, %PlankGames.TicTacToe.State{})
      :connectfour -> Map.put(new_state, :game_state, %PlankGames.ConnectFour.State{})
      :yahtzee -> Map.put(new_state, :game_state, %PlankGames.Yahtzee.State{})
    end
  end

  def start(state) do
    %PlankGames.Common.LobbyState{
      state
      | :has_started => true,
        :has_finished => false,
        :winner => nil
    }
    |> shuffle_players()
  end

  def add_player(state, player_id) do
    player_count = Enum.count(Map.get(state, :players))

    state
    |> Map.put(
      :players,
      state.players ++
        [
          %{
            :name => "Player #{player_count + 1}",
            :id => player_id
          }
        ]
    )
  end

  def remove_player(state, player_id) do
    case Enum.any?(state.players, fn x -> x.id == player_id end) do
      true ->
        {:ok,
         %PlankGames.Common.LobbyState{
           state
           | :players => Enum.filter(state.players, fn x -> x.id != player_id end),
             :has_finished => true
         }}

      false ->
        {:not_found, state}
    end
  end

  def leave_lobby(state, player_id) do
    state = Map.put(state, :connection_count, Map.get(state, :connection_count) - 1)

    if Map.get(state, :connection_count) == 0 do
      {:empty,
       %PlankGames.Common.LobbyState{
         state
         | :players => Enum.filter(state.players, fn x -> x.id != player_id end),
           :has_finished => true
       }}
    else
      case Enum.any?(state.players, fn x -> x.id == player_id end) do
        true ->
          {:player_left,
           %PlankGames.Common.LobbyState{
             state
             | :players => Enum.filter(state.players, fn x -> x.id != player_id end),
               :has_finished => true
           }}

        false ->
          {:ok, state}
      end
    end
  end

  def switch_player(state) do
    player_index = Enum.find_index(state.players, fn x -> x.id == state.current_player.id end)

    cond do
      player_index == Enum.count(state.players) - 1 ->
        Map.put(state, :current_player, Enum.at(state.players, 0))

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

  defp shuffle_players(state) do
    shuffled_players = Enum.shuffle(state.players)

    %PlankGames.Common.LobbyState{
      state
      | :players => shuffled_players,
        :current_player => Enum.at(shuffled_players, 0)
    }
  end
end
