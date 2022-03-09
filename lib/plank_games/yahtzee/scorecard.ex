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
            upper_section_bonus: 0,
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
        case category do
          :chance ->
            Map.put(
              scorecard,
              category,
              Enum.reduce(Map.values(dice), 0, &(Map.get(&1, :value) + &2))
            )

          :three_of_kind ->
            if is_x_of_kind?(dice, 3) do
              Map.put(
                scorecard,
                category,
                Enum.reduce(Map.values(dice), 0, &(Map.get(&1, :value) + &2))
              )
            else
              Map.put(scorecard, category, 0)
            end

          :four_of_kind ->
            if is_x_of_kind?(dice, 4) do
              Map.put(
                scorecard,
                category,
                Enum.reduce(Map.values(dice), 0, &(Map.get(&1, :value) + &2))
              )
            else
              Map.put(scorecard, category, 0)
            end

          :yahtzee ->
            if is_x_of_kind?(dice, 4) do
              Map.put(scorecard, category, 50)
            else
              Map.put(scorecard, category, 0)
            end

          :small_straight ->
            if is_straight?(dice, 4) do
              Map.put(scorecard, category, 30)
            else
              Map.put(scorecard, category, 0)
            end

          :large_straight ->
            if is_straight?(dice, 5) do
              Map.put(scorecard, category, 40)
            else
              Map.put(scorecard, category, 0)
            end

          _ ->
            scorecard
        end

      true ->
        Map.put(scorecard, category, 0)
    end
  end

  def is_complete?(scorecard),
    do: Enum.all?(Map.to_list(scorecard), fn x -> not is_nil(elem(x, 1)) end)

  def get_upper_section(), do: @upper_section

  def get_lower_section(), do: @lower_section

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
    total =
      Enum.reduce(
        Map.values(Map.take(scorecard, @upper_section)),
        0,
        &if(is_nil(&1), do: 0 + &2, else: &1 + &2)
      )

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
        Enum.reduce(
          Map.values(Map.take(scorecard, @lower_section)),
          0,
          &if(is_nil(&1), do: 0 + &2, else: &1 + &2)
        )
    )
  end

  defp grand_total(scorecard) do
    Map.put(
      scorecard,
      :grand_total,
      Map.get(scorecard, :upper_section) + Map.get(scorecard, :lower_section)
    )
  end

  defp is_x_of_kind?(dice, count),
    do:
      Enum.any?(Enum.frequencies_by(Map.values(dice), fn x -> Map.get(x, :value) end), fn x ->
        elem(x, 1) > count
      end)

  defp is_straight?(dice, count) do
    (Map.values(dice) ++ [%{value: 0}])
    |> Enum.map(fn x -> Map.get(x, :value) end)
    |> Enum.sort_by(fn x -> x end)
    |> Enum.chunk_every(2)
    |> Enum.take_while(fn x ->
      Enum.at(x, 0) == Enum.at(x, 1) - 1
    end)
    |> List.flatten()
    |> Enum.count(fn x -> x != 0 end) > count - 1
  end
end
