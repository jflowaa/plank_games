defmodule Common.LobbyState do
  defstruct [
    :id,
    :type,
    :player_one,
    :player_two,
    :current_player,
    :winner,
    :game_state,
    has_started: false,
    has_finished: false
  ]

  def new(lobby_id, type),
    do: %Common.LobbyState{:id => lobby_id, :type => type} |> Common.LobbyState.new()

  def new(state) do
    new_state = %Common.LobbyState{
      state
      | :winner => nil,
        :current_player => state.player_one,
        :has_finished => false
    }

    case Map.get(state, :type) do
      :tictactoe -> Map.put(new_state, :game_state, %TicTacToe.State{})
      :connectfour -> Map.put(new_state, :game_state, %ConnectFour.State{})
    end
  end

  def start(state),
    do: %Common.LobbyState{
      state
      | :has_started => true,
        :has_finished => false,
        :winner => nil,
        :current_player => state.player_one
    }

  def remove_client(state, client_id) do
    case client_id do
      x when x == state.player_one ->
        {:player_left, %Common.LobbyState{state | :player_one => nil, :has_started => false}}

      x when x == state.player_two ->
        {:player_left, %Common.LobbyState{state | :player_two => nil, :has_started => false}}

      _ ->
        {:ok, state}
    end
  end

  def switch_player(state) do
    case state.current_player do
      x when x == state.player_one ->
        Map.put(state, :current_player, Map.get(state, :player_two))

      x when x == state.player_two ->
        Map.put(state, :current_player, Map.get(state, :player_one))
    end
  end

  def should_close?(state),
    do: is_nil(Map.get(state, :player_one)) and is_nil(Map.get(state, :player_two))

  def is_joinable?(state, client_id) do
    cond do
      Map.get(state, :player_one) == client_id || Map.get(state, :player_two) == client_id ->
        false

      Map.get(state, :has_started) ->
        false

      true ->
        true
    end
  end

  def is_player?(state, client_id),
    do: Map.get(state, :player_one) == client_id || Map.get(state, :player_two) == client_id
end
