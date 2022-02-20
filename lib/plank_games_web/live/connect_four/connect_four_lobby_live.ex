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
        game_state = Map.get(state, :game_state)

        if state.has_finished do
          if state.winner do
            Phoenix.PubSub.broadcast(
              PlankGames.PubSub,
              @topic <> "_#{Map.get(socket.assigns, :lobby_id)}",
              {:change, "#{Map.get(game_state, :current_token)} has won"}
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
    game_state = Map.get(state, :game_state)

    socket
    |> assign(
      :client_count,
      ConnectFour.Presence.list(@topic <> "_#{Map.get(socket.assigns, :lobby_id)}") |> map_size
    )
    |> assign(:board, ConnectFour.State.list_rows(Map.get(game_state, :board)))
    |> assign(:has_finished, Map.get(state, :has_finished))
    |> assign(:has_started, Map.get(state, :has_started))
    |> assign(:current_token, Map.get(game_state, :current_token))
    |> assign(:winner, Map.get(state, :winner))
    |> assign(:player_token, determine_player_token(socket, state))
    |> assign(
      :show_join,
      Common.LobbyState.is_joinable?(state, Map.get(socket.assigns, :client_id))
    )
  end

  defp get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)

  defp determine_player_token(socket, state) do
    cond do
      Map.get(socket.assigns, :client_id) == Map.get(state, :player_one) -> "red"
      Map.get(socket.assigns, :client_id) == Map.get(state, :player_two) -> "black"
      true -> nil
    end
  end
end
