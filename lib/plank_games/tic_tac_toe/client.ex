defmodule PlankGames.TicTacToe.Client do
  require Logger
  @lobby_topic inspect(PlankGames.TicTacToe.Lobby)
  @activity_topic inspect(PlankGames.TicTacToe.Activity)

  def lookup(lobby_id) do
    try do
      GenServer.call(via_tuple(lobby_id), :get)
    catch
      :exit, _ ->
        Logger.info("Lobby not found, going to retry after 1 second")
        Process.sleep(1000)
        GenServer.call(via_tuple(lobby_id), :get)
    end
  end

  def new(lobby_id, player_id) do
    response = GenServer.call(via_tuple(lobby_id), {:new, player_id})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        {:change, "New game starting"}
      )
    end

    response
  end

  def join_game(lobby_id, player_id) do
    response = GenServer.call(via_tuple(lobby_id), {:join_game, player_id})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        {:change, "Player joined"}
      )
    end

    response
  end

  def leave_game(lobby_id, player_id) do
    response = GenServer.call(via_tuple(lobby_id), {:leave_game, player_id})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        {:change, "Player left, set game as finished"}
      )
    end

    response
  end

  def move(lobby_id, player_id, position) do
    response = GenServer.call(via_tuple(lobby_id), {:move, player_id, position})

    if response == :ok do
      state = lookup(lobby_id)

      if state.has_finished do
        if state.winner do
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{lobby_id}",
            {:change, "#{Map.get(Map.get(state, :game_state), :current_token)} has won"}
          )
        else
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "#{@lobby_topic}_#{lobby_id}",
            {:change, "Tie game"}
          )
        end
      else
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "#{@lobby_topic}_#{lobby_id}",
          :change
        )
      end
    end

    response
  end

  def leave_lobby(lobby_id, player_id) do
    response = GenServer.call(via_tuple(lobby_id), {:leave_lobby, player_id})

    case response do
      :player_left ->
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "#{@lobby_topic}_#{lobby_id}",
          {:change, "Player left, set game as finished"}
        )

      :empty ->
        close_lobby(lobby_id)

      _ ->
        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "#{@lobby_topic}_#{lobby_id}",
          :change
        )
    end

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      @activity_topic,
      :update
    )

    response
  end

  def join_lobby(lobby_id) do
    GenServer.call(via_tuple(lobby_id), :join_lobby)

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      "#{@lobby_topic}_#{lobby_id}",
      :change
    )

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      @activity_topic,
      :update
    )
  end

  defp close_lobby(lobby_id), do: GenServer.call(via_tuple(lobby_id), :close)

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.TicTacToe.LobbyRegistry, "lobby_#{lobby_id}"}}
end
