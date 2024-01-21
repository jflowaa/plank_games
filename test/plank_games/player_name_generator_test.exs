defmodule PlankGames.PlayerNameGenerator.Test do
  use ExUnit.Case, async: true

  setup do
    start_supervised(PlankGames.Common.PlayerNameGenerator)

    :ok
  end

  test "generate" do
    result = PlankGames.Common.PlayerNameGenerator.generate()
    assert elem(result, 0) == :ok
    assert is_bitstring(elem(result, 1))
  end

  test "generate different names" do
    {:ok, player_one} = PlankGames.Common.PlayerNameGenerator.generate()
    {:ok, player_two} = PlankGames.Common.PlayerNameGenerator.generate()
    assert player_one != player_two
  end
end
