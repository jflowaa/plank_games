defmodule PlankGamesWeb.PlankGames.TicTacToe.LobbyLive do
  use PlankGamesWeb, :live_view

  @lobby_topic inspect(PlankGames.TicTacToe.Lobby)

  @impl true
  def mount(params, session, socket) do
    PlankGames.TicTacToe.create(params["lobby_id"])

    if connected?(socket) do
      case PlankGames.TicTacToe.Client.connection_join(params["lobby_id"], session["player_id"]) do
        :ok ->
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{params["lobby_id"]}",
            :update
          )
      end

      Phoenix.PubSub.subscribe(PlankGames.PubSub, "#{@lobby_topic}_#{params["lobby_id"]}")

      PlankGamesWeb.Shared.LiveMonitor.monitor(self(), __MODULE__, %{
        id: socket.id,
        lobby_id: params["lobby_id"],
        player_id: session["player_id"]
      })
    end

    {:ok,
     socket
     |> assign(:player_id, session["player_id"])
     |> assign(:lobby_id, params["lobby_id"])
     |> stream(:messages, [
       %{id: System.unique_integer(), body: "Lobby '#{params["lobby_id"]}' joined"}
     ])
     |> fetch()}
  end

  def unmount({:shutdown, :closed}, %{id: _, lobby_id: lobby_id, player_id: player_id}) do
    PlankGames.TicTacToe.Client.connection_leave(lobby_id, player_id)

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      "#{@lobby_topic}_#{lobby_id}",
      :update
    )

    :ok
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    new_socket =
      case PlankGames.TicTacToe.Client.move(
             Map.get(socket.assigns, :lobby_id),
             Map.get(socket.assigns, :player_id),
             String.to_integer(position)
           ) do
        :not_started ->
          stream_insert(
            socket,
            :messages,
            %{
              id: System.unique_integer(),
              body: "Game has not started yet"
            }
          )

        :invalid_move ->
          stream_insert(socket, :messages, %{id: System.unique_integer(), body: "Invalid move"})

        :not_turn ->
          stream_insert(socket, :messages, %{id: System.unique_integer(), body: "Not your turn"})

        :winner ->
          {:ok, state} = PlankGames.TicTacToe.Client.lookup(socket.assigns.lobby_id)

          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            {:update, "Player '#{state.current_player.name}' won!"}
          )

          socket

        :tie ->
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            {:update, "Game ended in a tie!"}
          )

          socket

        :ok ->
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            :update
          )

          socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("join", _, socket) do
    new_socket =
      case PlankGames.TicTacToe.Client.join(socket.assigns.lobby_id, socket.assigns.player_id) do
        :full ->
          stream_insert(socket, :messages, %{
            id: System.unique_integer(),
            body: "There are already two players"
          })

        :already_joined ->
          stream_insert(socket, :messages, %{
            id: System.unique_integer(),
            body: "You're already joined"
          })

        :ok ->
          {:ok, state} = PlankGames.TicTacToe.Client.lookup(socket.assigns.lobby_id)

          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            {:lobby_message,
             "Player '#{PlankGames.Common.LobbyState.get_player_name_by_id(state, socket.assigns.player_id)}' joined the game"}
          )

          if state.has_started?,
            do:
              Phoenix.PubSub.broadcast(
                PlankGames.PubSub,
                "#{@lobby_topic}_#{socket.assigns.lobby_id}",
                {:update, "The game has started!"}
              )

          socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("leave", _, socket) do
    new_socket =
      case PlankGames.TicTacToe.Client.leave(socket.assigns.lobby_id, socket.assigns.player_id) do
        :ok ->
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            {:update, "A player left the game"}
          )

          if not socket.assigns.has_finished do
            {:ok, state} = PlankGames.TicTacToe.Client.lookup(socket.assigns.lobby_id)

            if state.has_finished?,
              do:
                Phoenix.PubSub.broadcast(
                  PlankGames.PubSub,
                  "#{@lobby_topic}_#{socket.assigns.lobby_id}",
                  {:update, "The game has ended early due to player leaving"}
                )
          end

          socket
      end

    {:noreply, fetch(new_socket)}
  end

  @impl true
  def handle_event("new", _, socket) do
    new_socket =
      case PlankGames.TicTacToe.Client.new(
             Map.get(socket.assigns, :lobby_id),
             Map.get(socket.assigns, :player_id)
           ) do
        :not_player ->
          stream_insert(socket, :messages, %{
            id: System.unique_integer(),
            body: "You're not a player in this game"
          })

        :not_finished ->
          stream_insert(socket, :messages, %{
            id: System.unique_integer(),
            body: "Game is not yet finished"
          })

        :ok ->
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{socket.assigns.lobby_id}",
            :update
          )

          socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:update, socket), do: {:noreply, fetch(socket)}

  @impl true
  def handle_info({:update, message}, socket),
    do:
      {:noreply,
       fetch(socket) |> stream_insert(:messages, %{id: System.unique_integer(), body: message})}

  @impl true
  def handle_info({:lobby_message, message}, socket),
    do:
      {:noreply,
       stream_insert(socket, :messages, %{
         id: System.unique_integer(),
         body: message
       })}

  defp fetch(socket) do
    case PlankGames.TicTacToe.Client.lookup(socket.assigns.lobby_id) do
      {:ok, state} ->
        game_state = Map.get(state, :game_state)

        socket
        |> assign(:failed_lobby, false)
        |> assign(:connections, PlankGames.Common.LobbyManager.get_connection_count(state))
        |> assign(:board, Map.get(game_state, :board))
        |> assign(:has_finished, Map.get(state, :has_finished?))
        |> assign(:has_started, Map.get(state, :has_started?))
        |> assign(
          :current_player,
          if(is_nil(state.current_player),
            do: nil,
            else: "#{state.current_player.name} (#{state.game_state.current_token})"
          )
        )
        |> assign(:winner, Map.get(state, :winner))
        |> assign(
          :player_name,
          PlankGames.Common.LobbyState.get_player_name_by_id(state, socket.assigns.player_id)
        )
        |> assign(
          :show_join,
          PlankGames.Common.LobbyManager.is_joinable?(state, Map.get(socket.assigns, :player_id))
        )
        |> assign(
          :is_player,
          PlankGames.Common.LobbyManager.is_player?(state, Map.get(socket.assigns, :player_id))
        )

      {:not_found} ->
        socket |> assign(:failed_lobby, true)
    end
  end

  defp render_square(position, assigns) do
    assigns =
      assigns
      |> assign(:extra_class, if(Enum.at(assigns.board, position) == "", do: "cursor-pointer"))
      |> assign(:position, position)

    ~H"""
    <td
      class={"border border-gray-500 #{@extra_class}"}
      phx-click="move"
      phx-value-position={"#{@position}"}
    >
      <svg width="100%" height="100%" preserveAspectRatio="none">
        <%= case Enum.at(@board, @position) do %>
          <% "x" -> %>
            <%= draw_svg_cross() %>
          <% "o" -> %>
            <circle
              cx="50%"
              cy="50%"
              r="25%"
              stroke="black"
              stroke-width="8"
              fill="white"
              fill-opacity="0.0"
            />
          <% _ -> %>
        <% end %>
      </svg>
    </td>
    """
  end

  defp draw_svg_cross(assigns \\ %{}) do
    ~H"""
    <line x1="25%" y1="25%" x2="75%" y2="75%" stroke="black" stroke-width="8" />
    <line x1="75%" y1="25%" x2="25%" y2="75%" stroke="black" stroke-width="8" />
    """
  end
end
