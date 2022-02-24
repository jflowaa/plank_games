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

  defstruct ones: nil,
            twos: nil,
            threes: nil,
            fours: nil,
            fives: nil,
            sixes: nil,
            upper_section_bonus: nil,
            upper_section: 0,
            three_of_kind: nil,
            four_of_kind: nil,
            full_house: nil,
            small_straight: nil,
            large_straight: nil,
            chance: nil,
            yahtzee: nil,
            yahtzee_bonus: 0,
            lower_section: 0,
            grand_total: 0

  def compute_total(scorecard) do
    scorecard |> upper_total() |> lower_total() |> grand_total()
  end

  def valid_category?(category),
    do: Enum.any?(@upper_section ++ @lower_section, fn x -> x == category end)

  def score_category(scorecard, category, dice) do
    cond do
      Enum.any?(@upper_section, fn x -> x == category end) ->
        compute_upper_section_category(
          scorecard,
          category,
          dice,
          Enum.find_index(@upper_section, fn x -> x == category end) + 1
        )

      Enum.any?(@lower_section, fn x -> x == category end) ->
        scorecard

      true ->
        Map.put(scorecard, category, 0)
    end
  end

  def is_complete?(scorecard),
    do: Enum.all?(Map.to_list(scorecard), fn x -> not is_nil(elem(x, 1)) end)

  defp compute_upper_section_category(scorecard, category, dice, target) do
    Map.put(
      scorecard,
      category,
      Enum.reduce(
        Enum.filter(Map.values(dice), fn value -> Map.get(value, :value) == target end),
        0,
        &(Map.get(&1, :value) + &2)
      )
    )
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
