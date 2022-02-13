defmodule ConnectFour.LobbyState do
  @rows 6
  @columns 7

  defstruct [
    :id,
    :player_one,
    :player_two,
    :current_player,
    :current_token,
    :winner,
    board: for(r <- 0..@rows, c <- 0..@columns, into: %{}, do: {{r, c}, :empty}),
    has_started: false,
    has_finished: false
  ]

  def display(board) do
    for row <- @rows..0 do
      for column <- 0..@columns do
        Map.get(board, {row, column})
      end
    end
  end
end
