defmodule ConnectFour.Lobby do
  use GenServer
  require Logger

  @rows 6
  @columns 7

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

  def join(lobby_id, player_id), do: GenServer.call(via_tuple(lobby_id), {:join, player_id})

  def move(lobby_id, player_id, position),
    do: GenServer.call(via_tuple(lobby_id), {:move, player_id, position})

  def new(lobby_id), do: GenServer.call(via_tuple(lobby_id), :new)

  def remove_client(lobby_id, client_id),
    do: GenServer.call(via_tuple(lobby_id), {:remove_client, client_id})

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: via_tuple(Keyword.get(opts, :lobby_id))) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(args) do
    Process.flag(:trap_exit, true)

    case Redix.command(:redix, ["GET", Keyword.get(args, :lobby_id)]) do
      {:ok, x} when not is_nil(x) ->
        {:ok, :erlang.binary_to_term(x)}

      _ ->
        {:ok, %ConnectFour.LobbyState{:id => Keyword.get(args, :lobby_id)}}
    end
  end

  def terminate(_, state) do
    if state.has_started do
      Redix.noreply_command(:redix, [
        "SET",
        Map.get(state, :id),
        :erlang.term_to_binary(state)
      ])
    end
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call(:new, _from, state) do
    if state.has_finished do
      {:reply, :ok,
       %ConnectFour.LobbyState{
         :id => state.id,
         :player_one => state.player_one,
         :player_two => state.player_two,
         :current_player => state.player_one,
         :current_token => :red,
         :has_started => true
       }}
    else
      {:reply, :not_finished, state}
    end
  end

  def handle_call({:join, player_id}, _from, state) do
    case state do
      %{:player_one => val} when is_nil(val) ->
        if player_id == state.player_two do
          {:reply, :already_joined, state}
        else
          {:reply, :ok, Map.put(state, :player_one, player_id)}
        end

      %{:player_two => val} when is_nil(val) ->
        if player_id == state.player_one do
          {:reply, :already_joined, state}
        else
          {:reply, :ok,
           %ConnectFour.LobbyState{
             state
             | :player_two => player_id,
               :current_player => state.player_one,
               :current_token => :red,
               :has_started => true
           }}
        end

      _ ->
        {:reply, :full, state}
    end
  end

  def handle_call({:move, _, _}, _from, state) when not state.has_started or state.has_finished,
    do: {:reply, :not_started, state}

  def handle_call({:move, player_id, _}, _from, state) when state.current_player != player_id,
    do: {:reply, :not_turn, state}

  def handle_call({:move, _, column}, _from, state) do
    if state.has_finished do
      {:reply, :ok, state}
    else
      result = drop_checker(state.board, column, state.current_token)

      if elem(result, 0) == :full do
        {:reply, :invalid_move, state}
      else
        case is_over(elem(result, 1), column) do
          {:tie, _} ->
            {:reply, :ok,
             Map.put(state, :board, elem(result, 1))
             |> Map.put(:has_finished, true)}

          {:over, _} ->
            {:reply, :ok,
             Map.put(state, :board, elem(result, 1))
             |> Map.put(:has_finished, true)
             |> Map.put(:winner, state.current_player)}

          _ ->
            {:reply, elem(result, 0), Map.put(state, :board, elem(result, 1)) |> switch_player}
        end
      end
    end
  end

  def handle_call({:remove_client, client_id}, _from, state) do
    case client_id do
      x when x == state.player_one ->
        {:reply, :player_left,
         %ConnectFour.LobbyState{
           :id => state.id,
           :player_two => state.player_two,
           :current_token => :red,
           :has_started => false
         }}

      x when x == state.player_two ->
        {:reply, :player_left,
         %ConnectFour.LobbyState{
           :id => state.id,
           :player_one => state.player_one,
           :current_token => :red,
           :has_started => false
         }}

      _ ->
        {:reply, :ok, state}
    end
  end

  defp via_tuple(lobby_id),
    do: {:via, Horde.Registry, {ConnectFour.Registry, "lobby_#{lobby_id}"}}

  defp switch_player(state) do
    case state.current_token do
      :red ->
        %ConnectFour.LobbyState{
          state
          | :current_token => :black,
            :current_player => state.player_two
        }

      _ ->
        %ConnectFour.LobbyState{
          state
          | :current_token => :red,
            :current_player => state.player_one
        }
    end
  end

  defp drop_checker(board, column, _) when column < 0 or column > @columns,
    do: {:invalid_drop, board}

  defp drop_checker(board, column, checker) do
    row = landed_row(board, column)

    cond do
      row == 7 -> {:full, board}
      true -> {:ok, Map.put(board, {row, column}, checker)}
    end
  end

  defp is_over(board, column) do
    row =
      landed_row(board, column)
      # minus 1 because we want the row at the time of drop
      |> minus(1)

    target_checker = Map.get(board, {row, column})

    cond do
      board
      |> list_rows()
      |> Enum.filter(fn x -> is_group_of_four?(x, target_checker) end)
      |> Enum.count() > 0 ->
        {:over, target_checker}

      board
      |> list_columns()
      |> Enum.filter(fn x -> is_group_of_four?(x, target_checker) end)
      |> Enum.count() > 0 ->
        {:over, target_checker}

      # list_rows(board)
      # |> List.flatten()
      # |> Enum.chunk_every(6)
      # |> Enum.filter(fn x ->
      #   is_group_of_four?(x, target_checker)
      # end)
      # |> Enum.count() > 4 ->
      #   {:over, target_checker}

      board
      |> list_rows()
      |> List.flatten()
      |> Enum.filter(fn x -> x == :empty end)
      |> Enum.count() == 0 ->
        {:tie, nil}

      Enum.take_while(row..@rows, fn x ->
        Map.get(board, {x, column + (x - row)}) == target_checker
      end)
      |> Enum.count() >= 4 ->
        {:over, target_checker}

      Enum.take_while(row..@rows, fn x ->
        Map.get(board, {x, column - (x - row)}) == target_checker
      end)
      |> Enum.count() >= 4 ->
        {:over, target_checker}

      Enum.take_while(row..0, fn x ->
        Map.get(board, {x, column + (row - x)}) == target_checker
      end)
      |> Enum.count() >= 4 ->
        {:over, target_checker}

      Enum.take_while(row..0, fn x ->
        Map.get(board, {x, column - (row - x)}) == target_checker
      end)
      |> Enum.count() >= 4 ->
        {:over, target_checker}

      true ->
        {:ongoing, nil}
    end
  end

  defp minus(x, y), do: x - y

  defp landed_row(board, column),
    do:
      Enum.take_while(0..@rows, fn x -> Map.get(board, {x, column}) != :empty end)
      |> Enum.count()

  defp is_group_of_four?(row, target_checker) do
    List.foldl(row, 0, fn entry, acc ->
      case {entry, acc} do
        {_, 4} -> 4
        {^target_checker, _} -> acc + 1
        _ -> 0
      end
    end) == 4
  end

  def list_rows(board) do
    for row <- @rows..0 do
      for column <- 0..@columns do
        Map.get(board, {row, column})
      end
    end
  end

  def list_columns(board) do
    for column <- 0..@columns do
      for row <- @rows..0 do
        Map.get(board, {row, column})
      end
    end
  end
end
