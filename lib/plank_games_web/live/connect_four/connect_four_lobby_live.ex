defmodule PlankGamesWeb.ConnectFourLobbyLive do
  use PlankGamesWeb, :live_view

  @topic inspect(ConnectFour.Lobby)
  @connect_four_topc inspect(ConnectFour.Activity)

  @impl true
  def mount(params, session, socket) do
    if ConnectFour.create(params["lobby_id"]) == {:ok} do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        @connect_four_topc,
        {:update, Map.get(socket.assigns, :lobby_id)}
      )
    end

    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PlankGames.PubSub, @topic <> "_#{params["lobby_id"]}")

    ConnectFour.Presence.track(
      self(),
      @topic <> "_#{params["lobby_id"]}",
      session["client_id"],
      %{}
    )

    {:ok,
     socket
     |> assign(:client_id, session["client_id"])
     |> assign(:lobby_id, params["lobby_id"])
     |> assign(:messages, ["Joined lobby"])
     |> fetch}
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    case ConnectFour.Lobby.move(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :client_id),
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
        state = ConnectFour.Lobby.lookup(Map.get(socket.assigns, :lobby_id))

        if state.has_finished do
          if state.winner do
            Phoenix.PubSub.broadcast(
              PlankGames.PubSub,
              @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
              {:change, "#{state.current_token} has won"}
            )
          else
            Phoenix.PubSub.broadcast(
              PlankGames.PubSub,
              @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
              {:change, "Tie game"}
            )
          end
        else
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
            {:change}
          )
        end

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("join", _, socket) do
    case ConnectFour.Lobby.join(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :client_id)
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
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
          {:change, "Player joined"}
        )

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("new", _, socket) do
    case ConnectFour.Lobby.new(Map.get(socket.assigns, :lobby_id)) do
      :not_finished ->
        {:noreply,
         assign(socket, :messages, ["Game is not yet finished" | get_tailing_messages(socket)])}

      :ok ->
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
          {:change, "New game starting"}
        )

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_info({:change, message}, socket),
    do: {:noreply, fetch(socket) |> assign(:messages, [message | get_tailing_messages(socket)])}

  @impl true
  def handle_info({:change}, socket), do: {:noreply, fetch(socket)}

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    Enum.each(diff.leaves, fn {client_id, _} ->
      if ConnectFour.Lobby.remove_client(Map.get(socket.assigns, :lobby_id), client_id) ==
           :player_left do
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
          {:change, "Player left, starting new game"}
        )
      end
    end)

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      @connect_four_topc,
      {:update, Map.get(socket.assigns, :lobby_id)}
    )

    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    state = ConnectFour.Lobby.lookup(Map.get(socket.assigns, :lobby_id))

    socket
    |> assign(
      :client_count,
      ConnectFour.Presence.list(@topic <> "_#{Map.get(socket.assigns, :lobby_id)}") |> map_size
    )
    |> assign(:board, Map.get(state, :board))
    |> assign(:has_finished, Map.get(state, :has_finished))
    |> assign(:has_started, Map.get(state, :has_started))
    |> assign(:current_token, Map.get(state, :current_token))
    |> assign(:winner, Map.get(state, :winner))
    |> assign(:player_token, determine_player_token(socket, state))
  end

  def render_square(%{position: position, board: board}, assigns \\ %{}) do
    ~H"""
    <td phx-click="move" phx-value-position={"#{position}"}>
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
      <line x1="25%"" y1="25%" x2="75%", y2="75%" stroke="black" stroke-width="8"/>
      <line x1="75%" y1="25%" x2="25%", y2="75%" stroke="black" stroke-width="8"/>
    """
  end

  defp get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)

  defp determine_player_token(socket, state) do
    cond do
      Map.get(socket.assigns, :client_id) == Map.get(state, :player_one) -> "x"
      Map.get(socket.assigns, :client_id) == Map.get(state, :player_two) -> "o"
      true -> nil
    end
  end
end
