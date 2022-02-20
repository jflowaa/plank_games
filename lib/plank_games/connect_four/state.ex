defmodule ConnectFour.State do
  @rows 6
  @columns 7

  defstruct board: for(r <- 0..@rows, c <- 0..@columns, into: %{}, do: {{r, c}, :empty}),
            current_token: :red

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

  def switch_token(state) do
    case state.current_token do
      :red ->
        %ConnectFour.State{state | :current_token => :black}

      :black ->
        %ConnectFour.State{state | :current_token => :red}
    end
  end

  def drop_checker(state, column) when column < 0 or column > @columns,
    do: {:invalid_move, state}

  def drop_checker(state, column) do
    row = landed_row(Map.get(state, :board), column)

    cond do
      row == 7 ->
        {:invalid_move, state}

      true ->
        {:ok,
         Map.put(
           state,
           :board,
           Map.put(Map.get(state, :board), {row, column}, Map.get(state, :current_token))
         )}
    end
  end

  def is_over(state) do
    cond do
      Map.get(state, :board)
      |> list_rows()
      |> Enum.filter(fn x -> is_group_of_four?(x, Map.get(state, :current_token)) end)
      |> Enum.count() > 0 ->
        :over

      Map.get(state, :board)
      |> list_columns()
      |> Enum.filter(fn x -> is_group_of_four?(x, Map.get(state, :current_token)) end)
      |> Enum.count() > 0 ->
        :over

      Map.get(state, :board)
      |> list_rows()
      |> List.flatten()
      |> Enum.reverse()
      |> Enum.chunk_every(9, 9, :discard)
      |> List.zip()
      |> Enum.filter(fn x ->
        is_group_of_four?(Tuple.to_list(x), Map.get(state, :current_token))
      end)
      |> Enum.count() > 0 ->
        :over

      Map.get(state, :board)
      |> list_rows()
      |> List.flatten()
      |> Enum.reverse()
      |> Enum.chunk_every(7, 7, :discard)
      |> List.zip()
      |> Enum.filter(fn x ->
        is_group_of_four?(Tuple.to_list(x), Map.get(state, :current_token))
      end)
      |> Enum.count() > 0 ->
        :over

      Map.get(state, :board)
      |> list_rows()
      |> List.flatten()
      |> Enum.filter(fn x -> x == :empty end)
      |> Enum.count() == 0 ->
        :tie

      true ->
        :ongoing
    end
  end

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
end
