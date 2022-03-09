defmodule PlankGamesWeb.ConnectFour.OverviewLive do
  use PlankGamesWeb, :live_view

  @topic inspect(ConnectorFour.Activity)

  @impl true
  def mount(_, _, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PlankGames.PubSub, @topic)

    ConnectFour.Activity.refresh()
    {:ok, fetch(socket) |> assign(:uuid, UUID.uuid4())}
  end

  @impl true
  def handle_info(:update, socket) do
    ConnectFour.Activity.refresh()

    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    state = ConnectFour.Activity.lookup()

    socket
    |> assign(:lobbies, state)
  end
end
