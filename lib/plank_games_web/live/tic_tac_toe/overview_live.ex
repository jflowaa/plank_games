defmodule PlankGamesWeb.TicTacToe.OverviewLive do
  use PlankGamesWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <PlankGamesWeb.Components.Lobby.listing id="lobby-listing" game="tic_tac_toe" lobbies={@lobbies} />

    <PlankGamesWeb.Components.Lobby.new_lobby id="new-lobby-form" game="tic_tac_toe" />
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok, fetch(socket) |> assign(:uuid, UUID.uuid4())}
  end

  @impl true
  def handle_info(:update, socket) do
    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    socket
    |> assign(:lobbies, [])
  end
end
