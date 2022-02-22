defmodule PlankGamesWeb.ConnectFourLobbyLive do
  use PlankGamesWeb, :live_view

  @topic inspect(ConnectFour.Lobby)

  @impl true
  def mount(params, session, socket) do
    ConnectFour.create(params["lobby_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PlankGames.PubSub, "#{@topic}_#{params["lobby_id"]}")

      Common.Monitor.monitor(%Common.Monitor{
        :game_pid => self(),
        :client_id => session["client_id"],
        :lobby_id => params["lobby_id"],
        :type => :connectfour
      })
    end

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
              "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
              {:change, "#{Map.get(game_state, :current_token)} has won"}
            )
          else
            Phoenix.PubSub.broadcast(
              PlankGames.PubSub,
              "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
              {:change, "Tie game"}
            )
          end
        else
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
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
          "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
          {:change, "Player joined"}
        )

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("new", _, socket) do
    case ConnectFour.Lobby.new(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :client_id)
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
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
          {:change, "New game starting"}
        )

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_event("leave", _, socket) do
    if ConnectFour.Lobby.remove_player(
         Map.get(socket.assigns, :lobby_id),
         Map.get(socket.assigns, :client_id)
       ) ==
         :player_left do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
        {:change, "Player left, starting new game"}
      )
    end

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_info({:change, message}, socket),
    do: {:noreply, fetch(socket) |> assign(:messages, [message | get_tailing_messages(socket)])}

  @impl true
  def handle_info({:change}, socket), do: {:noreply, fetch(socket)}

  defp fetch(socket) do
    state = ConnectFour.Lobby.lookup(Map.get(socket.assigns, :lobby_id))
    game_state = Map.get(state, :game_state)

    socket
    |> assign(:client_count, Map.get(state, :client_count))
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
    |> assign(
      :is_player,
      Common.LobbyState.is_player?(state, Map.get(socket.assigns, :client_id))
    )
  end

  defp get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)

  defp determine_player_token(socket, state) do
    cond do
      Enum.find_index(state.players, fn x -> x == Map.get(socket.assigns, :client_id) end) == 0 ->
        "red"

      Enum.find_index(state.players, fn x -> x == Map.get(socket.assigns, :client_id) end) == 1 ->
        "black"

      true ->
        nil
    end
  end
end
