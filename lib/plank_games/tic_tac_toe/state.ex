defmodule PlankGames.TicTacToe.State do
  defstruct board: [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            current_token: "x"

  def move(state, position) do
    case Enum.at(state.board, position) == "" do
      true ->
        {:ok, Map.put(state, :board, List.replace_at(state.board, position, state.current_token))}

      false ->
        {:invalid_move, state}
    end
  end

  def is_over?(state) do
    case state.board do
      [x, x, x, _, _, _, _, _, _] when x == state.current_token ->
        :winner

      [_, _, _, x, x, x, _, _, _] when x == state.current_token ->
        :winner

      [_, _, _, _, _, _, x, x, x] when x == state.current_token ->
        :winner

      [x, _, _, x, _, _, x, _, _] when x == state.current_token ->
        :winner

      [_, x, _, _, x, _, _, x, _] when x == state.current_token ->
        :winner

      [_, _, x, _, _, x, _, _, x] when x == state.current_token ->
        :winner

      [x, _, _, _, x, _, _, _, x] when x == state.current_token ->
        :winner

      [_, _, x, _, x, _, x, _, _] when x == state.current_token ->
        :winner

      _ ->
        case Enum.all?(state.board, &(&1 != "")) do
          true -> :tie
          false -> :ongoing
        end
    end
  end

  def switch_token(state) do
    case state.current_token do
      "x" ->
        %PlankGames.TicTacToe.State{state | :current_token => "o"}

      "o" ->
        %PlankGames.TicTacToe.State{state | :current_token => "x"}
    end
  end
end
