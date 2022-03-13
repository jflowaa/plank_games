defmodule PlankGames.Yahtzee.Client do
  require Logger
  @lobby_topic inspect(PlankGames.Yahtzee.Lobby)
  @activity_topic inspect(PlankGames.Yahtzee.Activity)

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

  def start(lobby_id) do
    response = GenServer.call(via_tuple(lobby_id), :start)

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      "#{@lobby_topic}_#{lobby_id}",
      :change
    )

    response
  end

  def roll(lobby_id, player_id) do
    response = GenServer.call(via_tuple(lobby_id), {:roll, player_id})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        :change
      )
    end

    response
  end

  def hold_die(lobby_id, player_id, die) do
    response = GenServer.call(via_tuple(lobby_id), {:hold_die, player_id, die})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        :change
      )
    end

    response
  end

  def release_die(lobby_id, player_id, die) do
    response = GenServer.call(via_tuple(lobby_id), {:release_die, player_id, die})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        :change
      )
    end

    response
  end

  def end_turn(lobby_id, player_id, category) do
    response = GenServer.call(via_tuple(lobby_id), {:end_turn, player_id, category})

    if response == :ok do
      Phoenix.PubSub.broadcast(
        PlankGames.PubSub,
        "#{@lobby_topic}_#{lobby_id}",
        :change
      )
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
    do: {:via, Registry, {PlankGames.Yahtzee.LobbyRegistry, "lobby_#{lobby_id}"}}
end
