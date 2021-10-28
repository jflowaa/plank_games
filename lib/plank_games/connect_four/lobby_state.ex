defmodule ConnectFour.LobbyState do
  defstruct [
    :id,
    :player_one,
    :player_two,
    :current_player,
    :current_token,
    :winner,
    board: [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
    ],
    has_started: false,
    has_finished: false
  ]
end
