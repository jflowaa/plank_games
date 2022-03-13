defmodule PlankGames.Common.Monitor do
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
        PlankGames.TicTacToe.Client.join_lobby(Map.get(details, :lobby_id))

      :connectfour ->
        PlankGames.ConnectFour.Client.join_lobby(Map.get(details, :lobby_id))

      :yahtzee ->
        PlankGames.Yahtzee.Client.join_lobby(Map.get(details, :lobby_id))
    end

    {:reply, :ok, Map.put(state, Map.get(details, :game_pid), new_details)}
  end

  def handle_info({:DOWN, _ref, :process, game_pid, _reason}, state) do
    {details, new_state} = Map.pop(state, game_pid)

    case Map.get(details, :type) do
      :tictactoe ->
        PlankGames.TicTacToe.Client.leave_lobby(
          Map.get(details, :lobby_id),
          Map.get(details, :player_id)
        )

      :connectfour ->
        PlankGames.ConnectFour.Client.leave_lobby(
          Map.get(details, :lobby_id),
          Map.get(details, :player_id)
        )

      :yahtzee ->
        PlankGames.Yahtzee.Client.leave_lobby(
          Map.get(details, :lobby_id),
          Map.get(details, :player_id)
        )
    end

    {:noreply, new_state}
  end
end
