defmodule PlankGames.Yahtzee.State do
  @dice_per_hand 5

  defstruct dice: for(i <- 1..@dice_per_hand, into: %{}, do: {i, %{value: nil, hold: false}}),
            scorecards: %{},
            roll_count: 0

  def add_scorecard(state, player_id),
    do:
      Map.put(
        state,
        :scorecards,
        Map.put(state.scorecards, player_id, %PlankGames.Yahtzee.Scorecard{})
      )

  def remove_scorecard(state, player_id),
    do: Map.put(state, :scorecards, elem(Map.pop(state.scorecards, player_id), 1))

  def compute_player_totals(state) do
    Map.put(
      state,
      :scorecards,
      for(
        x <- Map.to_list(state.scorecards),
        into: %{},
        do: {elem(x, 0), PlankGames.Yahtzee.Scorecard.compute_total(elem(x, 1))}
      )
    )
  end

  def end_turn(state, player_id, category) do
    cond do
      not PlankGames.Yahtzee.Scorecard.valid_category?(category) ->
        {:invalid_category, state}

      is_nil(Map.get(state.scorecards, player_id)) ->
        {:invalid_player, state}

      not is_nil(Map.get(Map.get(state.scorecards, player_id), category)) ->
        {:category_set, state}

      Map.get(state, :roll_count) == 0 ->
        {:not_rolled, state}

      true ->
        {:ok,
         Map.put(
           state,
           :scorecards,
           Map.put(
             state.scorecards,
             player_id,
             PlankGames.Yahtzee.Scorecard.score_category(
               Map.get(state.scorecards, player_id),
               category,
               state.dice
             )
           )
         )
         |> Map.put(:roll_count, 0)
         |> Map.put(
           :dice,
           for({k, v} <- Map.get(state, :dice), into: %{}, do: {k, Map.put(v, :hold, false)})
         )}
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
    if is_nil(Map.get(Map.get(state.dice, die), :value)) or Map.get(state, :roll_count) == 0 do
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
