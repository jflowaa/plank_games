defmodule ConnectFour.Presence do
  use Phoenix.Presence,
    otp_app: :connect_four,
    pubsub_server: PlankGames.PubSub
end
