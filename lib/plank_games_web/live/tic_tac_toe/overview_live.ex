defmodule PlankGamesWeb.TicTacToe.OverviewLive do
  use PlankGamesWeb, :live_view
  @topic inspect(TicTacToe.Activity)

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={PlankGamesWeb.Live.Common.OverviewComponent} id="overview" game="tictactoe" lobbies={@lobbies}/>
    """
  end

  @impl true
  def mount(_, _, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PlankGames.PubSub, @topic)

    TicTacToe.Activity.refresh()
    {:ok, fetch(socket) |> assign(:uuid, UUID.uuid4())}
  end

  @impl true
  def handle_info(:update, socket) do
    TicTacToe.Activity.refresh()

    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    state = TicTacToe.Activity.lookup()

    socket
    |> assign(:lobbies, state)
  end
end
