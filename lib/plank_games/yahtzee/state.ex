defmodule Yahtzee.State do
  @dice_per_hand 5

  defstruct dice: for(i <- 1..@dice_per_hand, into: %{}, do: {i, %{value: nil, hold: false}}),
            scorecards: %{player_id: %Yahtzee.Scorecard{}}

  def compute_player_totals(state) do
    Map.put(
      state,
      :scorecards,
      for(
        x <- Map.to_list(Map.get(state, :scorecards)),
        into: %{player_id: %Yahtzee.Scorecard{}},
        do: {elem(x, 0), Yahtzee.Scorecard.compute_total(elem(x, 1))}
      )
    )
  end

  def roll_dice(state) do
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
  end
end
