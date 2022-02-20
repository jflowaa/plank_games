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

  def new(lobby_id, type) do
    %Common.LobbyState{:id => lobby_id, :type => type} |> Common.LobbyState.new()
  end

  def new(state) do
    new_state = %Common.LobbyState{
      state
      | :winner => nil,
        :current_player => state.player_one,
        :has_started => false,
        :has_finished => false
    }

    case Map.get(state, :type) do
      :tictactoe -> Map.put(new_state, :game_state, %TicTacToe.State{})
      :connectfour -> Map.put(new_state, :game_state, %ConnectFour.State{})
    end
  end

  def start(state) do
    %Common.LobbyState{
      state
      | :has_started => true,
        :has_finished => false,
        :winner => nil,
        :current_player => state.player_one
    }
  end

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
end
