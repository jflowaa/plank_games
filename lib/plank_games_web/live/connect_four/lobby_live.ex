defmodule PlankGamesWeb.PlankGames.ConnectFour.LobbyLive do
  use PlankGamesWeb, :live_view

  @topic inspect(PlankGames.ConnectFour.Lobby)

  @impl true
  def mount(params, session, socket) do
    PlankGames.ConnectFour.create(params["lobby_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PlankGames.PubSub, "#{@topic}_#{params["lobby_id"]}")

      PlankGames.Common.Monitor.monitor(%PlankGames.Common.Monitor{
        :game_pid => self(),
        :player_id => session["player_id"],
        :lobby_id => params["lobby_id"],
        :type => :connectfour
      })
    end

    {:ok,
     socket
     |> assign(:player_id, session["player_id"])
     |> assign(:lobby_id, params["lobby_id"])
     |> assign(:messages, ["Joined lobby"])
     |> fetch}
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    case PlankGames.ConnectFour.Client.move(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id),
           String.to_integer(position)
         ) do
      :not_started ->
        {:noreply,
         assign(socket, :messages, ["Game is not started" | get_tailing_messages(socket)])}

      :invalid_move ->
        {:noreply, assign(socket, :messages, ["Invalid move" | get_tailing_messages(socket)])}

      :not_turn ->
        {:noreply, assign(socket, :messages, ["Not your turn" | get_tailing_messages(socket)])}

      :ok ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("join", _, socket) do
    case PlankGames.ConnectFour.Client.join_game(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id)
         ) do
      :full ->
        {:noreply,
         assign(socket, :messages, [
           "There are already two players" | get_tailing_messages(socket)
         ])}

      :already_joined ->
        {:noreply,
         assign(socket, :messages, ["You're already joined" | get_tailing_messages(socket)])}

      :ok ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("new", _, socket) do
    case PlankGames.ConnectFour.Client.new(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id)
         ) do
      :not_player ->
        {:noreply,
         assign(socket, :messages, [
           "You're not a player in this game" | get_tailing_messages(socket)
         ])}

      :not_finished ->
        {:noreply,
         assign(socket, :messages, ["Game is not yet finished" | get_tailing_messages(socket)])}

      :ok ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("leave", _, socket) do
    PlankGames.ConnectFour.Client.leave_game(
      Map.get(socket.assigns, :lobby_id),
      Map.get(socket.assigns, :player_id)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:change, message}, socket),
    do: {:noreply, fetch(socket) |> assign(:messages, [message | get_tailing_messages(socket)])}

  @impl true
  def handle_info(:change, socket), do: {:noreply, fetch(socket)}

  defp fetch(socket) do
    state = PlankGames.ConnectFour.Client.lookup(Map.get(socket.assigns, :lobby_id))
    game_state = Map.get(state, :game_state)

    socket
    |> assign(:connection_count, Map.get(state, :connection_count))
    |> assign(:board, PlankGames.ConnectFour.State.list_rows(Map.get(game_state, :board)))
    |> assign(:has_finished, Map.get(state, :has_finished))
    |> assign(:has_started, Map.get(state, :has_started))
    |> assign(:current_player, Map.get(game_state, :current_token))
    |> assign(:winner, Map.get(state, :winner))
    |> assign(:player_name, determine_player_token(socket, state))
    |> assign(
      :show_join,
      PlankGames.Common.LobbyState.is_joinable?(state, Map.get(socket.assigns, :player_id))
    )
    |> assign(
      :is_player,
      PlankGames.Common.LobbyState.is_player?(state, Map.get(socket.assigns, :player_id))
    )
  end

  defp get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)

  defp determine_player_token(socket, state) do
    cond do
      Enum.find_index(state.players, fn x -> x.id == Map.get(socket.assigns, :player_id) end) == 0 ->
        "red"

      Enum.find_index(state.players, fn x -> x.id == Map.get(socket.assigns, :player_id) end) == 1 ->
        "black"

      true ->
        nil
    end
  end
end
