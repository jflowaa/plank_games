defmodule PlankGames.Stats.Registry do
  use GenServer
  require Logger

  @topic inspect(PlankGamesWeb.Stats.DashboardLive)

  def lookup(), do: GenServer.call(GenServer.whereis({:global, __MODULE__}), :get)

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_) do
    # todo: store this pid?
    :cpu_sup.start()
    Process.send_after(self(), :update, 1000)

    {:ok,
     %{
       PlankGames.TicTacToe.LobbySupervisor => %{},
       PlankGames.ConnectFour.LobbySupervisor => %{},
       PlankGames.Yahtzee.LobbySupervisor => %{},
       :memory_usage => Float.round(:erlang.memory(:total) / 1024 / 1024, 2),
       :cpu_usage => Float.round(:cpu_sup.util(), 2)
     }}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}
  def handle_info(:update, _), do: {:noreply, get_stats()}

  defp get_stats() do
    stats =
      Enum.reduce(
        [
          PlankGames.TicTacToe.LobbySupervisor,
          PlankGames.ConnectFour.LobbySupervisor,
          PlankGames.Yahtzee.LobbySupervisor
        ],
        %{},
        fn x, state ->
          stats = get_connection_count(x)
          Map.put(state, x, stats)
        end
      )
      |> Map.put(:memory_usage, Float.round(:erlang.memory(:total) / 1024 / 1024, 2))
      |> Map.put(:cpu_usage, Float.round(:cpu_sup.util(), 2))

    Phoenix.PubSub.broadcast(
      PlankGames.PubSub,
      @topic,
      {:update, stats}
    )

    Process.send_after(self(), :update, 30 * 1000)

    stats
  end

  defp get_connection_count(game) do
    children = Supervisor.which_children(game)

    %{
      :games => Enum.count(children),
      :connections =>
        Enum.reduce(children, 0, fn child, _ ->
          :sys.get_state(elem(child, 1)).connection_count
        end)
    }
  end
end
