defmodule PlankGames.Common.LobbyState do
  defstruct [
    :id,
    :type,
    :current_player,
    :winner,
    :game_state,
    players: [],
    has_started?: false,
    has_finished?: false,
    connections: %{}
  ]

  def get_player_name_by_id(state, player_id) do
    case Enum.find(state.players, fn x -> x.id == player_id end) do
      x when is_map(x) -> x.name
      _ -> nil
    end
  end
end
