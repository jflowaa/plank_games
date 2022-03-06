defmodule PlankGamesWeb.YahtzeeLobbyLive do
  use PlankGamesWeb, :live_view

  @topic inspect(Yahtzee.Lobby)

  @impl true
  def mount(params, session, socket) do
    Yahtzee.create(params["lobby_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PlankGames.PubSub, "#{@topic}_#{params["lobby_id"]}")

      Common.Monitor.monitor(%Common.Monitor{
        :game_pid => self(),
        :player_id => session["player_id"],
        :lobby_id => params["lobby_id"],
        :type => :yahtzee
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
  def handle_event("roll", _, socket) do
    case Yahtzee.Lobby.roll(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id)
         ) do
      :not_started ->
        {:noreply,
         assign(socket, :messages, ["Game is not started" | get_tailing_messages(socket)])}

      :not_turn ->
        {:noreply, assign(socket, :messages, ["Not your turn" | get_tailing_messages(socket)])}

      :max_rolls ->
        {:noreply, assign(socket, :messages, ["Max rolls" | get_tailing_messages(socket)])}

      :ok ->
        state = Yahtzee.Lobby.lookup(Map.get(socket.assigns, :lobby_id))
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
    case Yahtzee.Lobby.join(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id)
         ) do
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
    case Yahtzee.Lobby.new(
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
    if Yahtzee.Lobby.remove_player(
         Map.get(socket.assigns, :lobby_id),
         Map.get(socket.assigns, :player_id)
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
  def handle_event("start", _, socket) do
    Yahtzee.Lobby.start(Map.get(socket.assigns, :lobby_id))

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_event("hold", %{"die" => die}, socket) do
    Yahtzee.Lobby.hold_die(
      Map.get(socket.assigns, :lobby_id),
      Map.get(socket.assigns, :player_id),
      String.to_integer(die)
    )

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_event("release", %{"die" => die}, socket) do
    Yahtzee.Lobby.release_die(
      Map.get(socket.assigns, :lobby_id),
      Map.get(socket.assigns, :player_id),
      String.to_integer(die)
    )

    {:noreply, fetch(socket)}
  end

  @impl true
  def handle_event("end_turn", %{"category" => category}, socket) do
    case Yahtzee.Lobby.end_turn(
           Map.get(socket.assigns, :lobby_id),
           Map.get(socket.assigns, :player_id),
           String.to_atom(category)
         ) do
      :invalid_category ->
        {:noreply,
         assign(socket, :messages, [
           "Invalid category" | get_tailing_messages(socket)
         ])}

      :invalid_player ->
        {:noreply,
         assign(socket, :messages, [
           "Not your turn" | get_tailing_messages(socket)
         ])}

      :category_set ->
        {:noreply,
         assign(socket, :messages, [
           "Category already set" | get_tailing_messages(socket)
         ])}

      :not_rolled ->
        {:noreply,
         assign(socket, :messages, [
           "Roll first before setting a category" | get_tailing_messages(socket)
         ])}

      :ok ->
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "#{@topic}_#{Map.get(socket.assigns, :lobby_id)}",
          {:change}
        )

        {:noreply, fetch(socket)}
    end
  end

  @impl true
  def handle_info({:change, message}, socket),
    do: {:noreply, fetch(socket) |> assign(:messages, [message | get_tailing_messages(socket)])}

  @impl true
  def handle_info({:change}, socket), do: {:noreply, fetch(socket)}

  def fetch(socket) do
    state = Yahtzee.Lobby.lookup(Map.get(socket.assigns, :lobby_id))
    game_state = Map.get(state, :game_state)

    player =
      Enum.find(Map.get(state, :players), fn x -> x.id == Map.get(socket.assigns, :player_id) end)

    socket
    |> assign(:connection_count, Map.get(state, :connection_count))
    |> assign(:roll_count, Map.get(game_state, :roll_count))
    |> assign(:has_finished, Map.get(state, :has_finished))
    |> assign(:has_started, Map.get(state, :has_started))
    |> assign(:scorecards, Map.get(game_state, :scorecards))
    |> assign(:dice, Map.get(game_state, :dice))
    |> assign(
      :player_name,
      case player do
        nil -> nil
        _ -> player.name
      end
    )
    |> assign(
      :current_player,
      if not is_nil(Map.get(state, :current_player)) do
        state.current_player.name
      end
    )
    |> assign(:winner, Map.get(state, :winner))
    |> assign(
      :show_join,
      Common.LobbyState.is_joinable?(state, Map.get(socket.assigns, :player_id))
    )
    |> assign(
      :is_player,
      Common.LobbyState.is_player?(state, Map.get(socket.assigns, :player_id))
    )
  end

  def get_tailing_messages(socket), do: Enum.take(Map.get(socket.assigns, :messages), 5)
end
