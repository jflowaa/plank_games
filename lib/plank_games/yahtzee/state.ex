defmodule Yahtzee.State do
  @dice_per_hand 5

  defstruct dice: for(i <- 1..@dice_per_hand, into: %{}, do: {i, %{value: nil, hold: false}}),
            scorecards: %{},
            roll_count: 0

  def add_player(state, player_id) do
    Map.put(state, :scorecards, Map.put(state.scorecards, player_id, %Yahtzee.Scorecard{}))
  end

  def remove_player(state, player_id) do
    Map.put(state, :scorecards, elem(Map.pop(state.scorecards, player_id), 1))
  end

  def compute_player_totals(state) do
    case Enum.all?(Map.to_list(state.scorecards), fn x ->
           Yahtzee.Scorecard.is_complete?(elem(x, 1))
         end) do
      true ->
        {:ok,
         Map.put(
           state,
           :scorecards,
           for(
             x <- Map.to_list(state.scorecards),
             into: %{player_id: %Yahtzee.Scorecard{}},
             do: {elem(x, 0), Yahtzee.Scorecard.compute_total(elem(x, 1))}
           )
         )}

      false ->
        {:not_finished, state}
    end
  end

  def end_turn(state, player_id, category) do
    cond do
      not Yahtzee.Scorecard.valid_category?(category) ->
        {:invalid_category, state}

      is_nil(Map.get(state.scorecards, player_id)) ->
        {:invalid_player, state}

      is_nil(Map.get(Map.get(state.scorecards, player_id), category)) ->
        {:category_set, state}

      true ->
        {:ok,
         Map.put(
           state,
           :scorecards,
           Map.put(
             state.scorecards,
             player_id,
             Yahtzee.Scorecard.score_category(
               Map.get(state.scorecards, player_id),
               category,
               state.dice
             )
           )
         )
         |> Map.put(:roll_count, 0)}
    end
  end

  def roll_dice(state) do
    if Map.get(state, :roll_count) == 3 do
      {:max_rolls, state}
    else
      {:ok,
       Map.put(
         state,
         :dice,
         for x <- Map.to_list(Map.get(state, :dice)), into: %{} do
           if Map.get(elem(x, 1), :hold) do
             {elem(x, 0), elem(x, 1)}
           else
             {elem(x, 0), %{:value => :rand.uniform(6), :hold => false}}
           end
         end
       )
       |> Map.put(:roll_count, Map.get(state, :roll_count) + 1)}
    end
  end

  def hold_die(state, die) do
    if is_nil(Map.get(Map.get(state.dice, die), :value)) do
      state
    else
      Map.put(
        state,
        :dice,
        Map.put(state.dice, die, Map.put(Map.get(state.dice, die), :hold, true))
      )
    end
  end

  def release_die(state, die),
    do:
      Map.put(
        state,
        :dice,
        Map.put(state.dice, die, Map.put(Map.get(state.dice, die), :hold, false))
      )
end
