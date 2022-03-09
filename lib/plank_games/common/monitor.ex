defmodule Common.Monitor do
  use GenServer

  defstruct [
    :game_pid,
    :type,
    :player_id,
    :lobby_id,
    :ref
  ]

  def monitor(details),
    do: GenServer.call(GenServer.whereis({:global, __MODULE__}), {:monitor, details})

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:monitor, details}, _from, state) do
    new_details = Map.put(details, :ref, Process.monitor(Map.get(details, :game_pid)))

    case Map.get(details, :type) do
      :tictactoe ->
        TicTacToe.Lobby.add_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "TicTacToe.Activity",
          :update
        )

      :connectfour ->
        ConnectFour.Lobby.add_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "ConnectFour.Activity",
          :update
        )

      :yahtzee ->
        Yahtzee.Lobby.add_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "Yahtzee.Activity",
          :update
        )
    end

    {:reply, :ok, Map.put(state, Map.get(details, :game_pid), new_details)}
  end

  def handle_info({:DOWN, _ref, :process, game_pid, _reason}, state) do
    {details, new_state} = Map.pop(state, game_pid)

    case Map.get(details, :type) do
      :tictactoe ->
        if TicTacToe.Lobby.remove_player(
             Map.get(details, :lobby_id),
             Map.get(details, :player_id)
           ) == :player_left do
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "TicTacToe.Lobby_#{Map.get(details, :lobby_id)}",
            {:change, "Player left, starting new game"}
          )
        end

        TicTacToe.Lobby.remove_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "TicTacToe.Activity",
          :update
        )

      :connectfour ->
        if ConnectFour.Lobby.remove_player(
             Map.get(details, :lobby_id),
             Map.get(details, :player_id)
           ) == :player_left do
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "ConnectFour.Lobby_#{Map.get(details, :lobby_id)}",
            {:change, "Player left, starting new game"}
          )
        end

        ConnectFour.Lobby.remove_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "ConnectFour.Activity",
          :update
        )

      :yahtzee ->
        if Yahtzee.Lobby.remove_player(
             Map.get(details, :lobby_id),
             Map.get(details, :player_id)
           ) == :player_left do
          Phoenix.PubSub.broadcast(
            PlankGames.PubSub,
            "Yahtzee.Lobby_#{Map.get(details, :lobby_id)}",
            {:change, "Player left, starting new game"}
          )
        end

        Yahtzee.Lobby.remove_player(Map.get(details, :lobby_id))

        Phoenix.PubSub.broadcast(
          PlankGames.PubSub,
          "Yahtzee.Activity",
          :update
        )
    end

    {:noreply, new_state}
  end
end
