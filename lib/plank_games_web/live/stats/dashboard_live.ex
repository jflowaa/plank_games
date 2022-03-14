defmodule PlankGamesWeb.Stats.DashboardLive do
  use PlankGamesWeb, :live_view

  @topic inspect(PlankGamesWeb.Stats.DashboardLive)

  @impl true
  def mount(_, _, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PlankGames.PubSub, @topic)

    {:ok,
     socket
     |> assign(:stats, PlankGames.Stats.Registry.lookup())}
  end

  @impl true
  def handle_info({:update, stats}, socket) do
    {:noreply, socket |> assign(:stats, stats)}
  end
end
