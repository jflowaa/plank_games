defmodule PlankGamesWeb.PlankGames.TicTacToe.LobbyLive do
  use PlankGamesWeb, :live_view

  @topic inspect(PlankGames.TicTacToe.Lobby)

  @impl true
  def mount(params, session, socket) do
    PlankGames.TicTacToe.create(params["lobby_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PlankGames.PubSub, "#{@topic}_#{params["lobby_id"]}")

      PlankGames.Common.Monitor.monitor(%PlankGames.Common.Monitor{
        :game_pid => self(),
        :player_id => session["player_id"],
        :lobby_id => params["lobby_id"],
        :type => :tictactoe
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
    case PlankGames.TicTacToe.Client.move(
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
        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("join", _, socket) do
    case PlankGames.TicTacToe.Client.join_game(
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
        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("new", _, socket) do
    case PlankGames.TicTacToe.Client.new(
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
        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("leave", _, socket) do
    PlankGames.TicTacToe.Client.leave_game(
      Map.get(socket.assigns, :lobby_id),
      Map.get(socket.assigns, :player_id)
    )

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_info({:change, message}, socket),
    do: {:noreply, fetch(socket) |> assign(:messages, [message | get_tailing_messages(socket)])}

  @impl true
  def handle_info(:change, socket), do: {:noreply, fetch(socket)}

  defp fetch(socket) do
    state = PlankGames.TicTacToe.Client.lookup(Map.get(socket.assigns, :lobby_id))
    game_state = Map.get(state, :game_state)

    socket
    |> assign(:connection_count, Map.get(state, :connection_count))
    |> assign(:board, Map.get(game_state, :board))
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

  def render_square(%{position: position, board: board}, assigns \\ %{}) do
    ~H"""
    <td class={"border border-gray-500 #{if Enum.at(board, position) == "", do: "cursor-pointer"}"} phx-click="move" phx-value-position={"#{position}"}>
      <svg width="100%" height="100%" preserveAspectRatio="none">
          <%= case Enum.at(board, position) do %>
            <% "x" -> %>
              <%= draw_svg_cross() %>
            <% "o" -> %>
              <circle cx="50%" cy="50%" r="25%" stroke="black" stroke-width="8" fill="white" fill-opacity="0.0"/>
            <% _ -> %>
          <% end %>
      </svg>
    </td>
    """
  end

  def draw_svg_cross(assigns \\ %{}) do
    ~H"""
      <line x1="25%" y1="25%" x2="75%", y2="75%" stroke="black" stroke-width="8"/>
      <line x1="75%" y1="25%" x2="25%", y2="75%" stroke="black" stroke-width="8"/>
    """
  end

  defp get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)

  defp determine_player_token(socket, state) do
    cond do
      Enum.find_index(state.players, fn x -> x.id == Map.get(socket.assigns, :player_id) end) == 0 ->
        "x"

      Enum.find_index(state.players, fn x -> x.id == Map.get(socket.assigns, :player_id) end) == 1 ->
        "o"

      true ->
        nil
    end
  end
end
