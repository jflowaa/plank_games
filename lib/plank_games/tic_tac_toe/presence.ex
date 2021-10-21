defmodule TicTacToe.Presence do
  use Phoenix.Presence,
    otp_app: :tic_tac_toe,
    pubsub_server: PlankGames.PubSub
end
