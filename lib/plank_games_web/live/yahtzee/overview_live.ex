defmodule PlankGamesWeb.Yahtzee.OverviewLive do
  use PlankGamesWeb, :live_view
  @topic inspect(Yahtzee.Activity)

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={PlankGamesWeb.Live.Common.OverviewComponent} id="overview" game="yahtzee" lobbies={@lobbies}/>
    """
  end

  @impl true
  def mount(_, _, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PlankGames.PubSub, @topic)

    Yahtzee.Activity.refresh()
    {:ok, fetch(socket) |> assign(:uuid, UUID.uuid4())}
  end

  @impl true
  def handle_info(:update, socket) do
    Yahtzee.Activity.refresh()

    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    state = Yahtzee.Activity.lookup()

    socket
    |> assign(:lobbies, state)
  end
end
