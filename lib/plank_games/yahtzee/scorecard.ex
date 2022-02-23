defmodule Yahtzee.Scorecard do
  @upper_section [:ones, :twos, :threes, :fours, :fives, :sixes]
  @upper_section_bonus_threshold 62
  @upper_section_bonus 25
  @lower_section [
    :three_of_kind,
    :four_of_kind,
    :full_house,
    :small_straight,
    :large_straight,
    :chance,
    :yahtzee
  ]
  @yahtzee_bonus 100

  defstruct ones: 0,
            twos: 0,
            threes: 0,
            fours: 0,
            fives: 0,
            sixes: 0,
            upper_section_bonus: 0,
            upper_section: 0,
            three_of_kind: 0,
            four_of_kind: 0,
            full_house: 0,
            small_straight: 0,
            large_straight: 0,
            chance: 0,
            yahtzee: 0,
            yahtzee_bonus: 0,
            lower_section: 0,
            grand_total: 0

  def compute_total(scorecard) do
    scorecard |> upper_total() |> lower_total() |> grand_total()
  end

  defp upper_total(scorecard) do
    total = Enum.reduce(Map.values(Map.take(scorecard, @upper_section)), 0, &(&1 + &2))

    if total > @upper_section_bonus_threshold do
      Map.put(
        Map.put(scorecard, :upper_section_bonus, @upper_section_bonus),
        :upper_section,
        total + @upper_section_bonus
      )
    else
      Map.put(scorecard, :upper_section, total)
    end
  end

  defp lower_total(scorecard) do
    Map.put(
      scorecard,
      :lower_section,
      @yahtzee_bonus * Map.get(scorecard, :yahtzee_bonus) +
        Enum.reduce(Map.values(Map.take(scorecard, @lower_section)), 0, &(&1 + &2))
    )
  end

  defp grand_total(scorecard) do
    Map.put(
      scorecard,
      :grand_total,
      Map.get(scorecard, :upper_section) + Map.get(scorecard, :lower_section)
    )
  end
end
