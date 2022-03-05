defmodule Common.LobbyState do
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
    do: %Common.LobbyState{:id => lobby_id, :type => type} |> Common.LobbyState.new()

  def new(state) do
    new_state =
      %Common.LobbyState{
        state
        | :winner => nil,
          :has_finished => false
      }
      |> shuffle_players()

    case Map.get(state, :type) do
      :tictactoe -> Map.put(new_state, :game_state, %TicTacToe.State{})
      :connectfour -> Map.put(new_state, :game_state, %ConnectFour.State{})
      :yahtzee -> Map.put(new_state, :game_state, %Yahtzee.State{})
    end
  end

  def start(state) do
    %Common.LobbyState{
      state
      | :has_started => true,
        :has_finished => false,
        :winner => nil
    }
    |> shuffle_players()
  end

  def add_player(state, player_id) do
    player_count = Enum.count(Map.get(state, :players))

    Map.put(
      state,
      :players,
      state.players ++
        [
          %{
            :name => "Player#{player_count + 1}",
            :id => player_id
          }
        ]
    )
  end

  def remove_player(state, player_id) do
    case Enum.any?(state.players, fn x -> x.id == player_id end) do
      true ->
        {:player_left,
         %Common.LobbyState{
           state
           | :players => Enum.filter(state.players, fn x -> x.id != player_id end),
             :has_started => false
         }}

      false ->
        {:ok, state}
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

  def should_close?(state), do: state.connection_count <= 0

  def is_joinable?(state, player_id) do
    cond do
      is_player?(state, player_id) ->
        false

      Map.get(state, :has_started) ->
        false

      true ->
        true
    end
  end

  def is_player?(state, player_id), do: Enum.any?(state.players, fn x -> x.id == player_id end)

  defp shuffle_players(state) do
    shuffled_players = Enum.shuffle(state.players)

    %Common.LobbyState{
      state
      | :players => shuffled_players,
        :current_player => Enum.at(shuffled_players, 0)
    }
  end
end
