defmodule PlankGames.ConnectFour.GameTest do
  use ExUnit.Case, async: true

  @column_one 0
  @column_two 1
  @column_three 2
  @column_four 3
  @column_five 4
  @column_six 5
  @column_seven 6

  setup do
    start_supervised(PlankGames.ConnectFour)

    [lobby_id: UUID.uuid4()]
  end

  def start_game(lobby_id) do
    PlankGames.ConnectFour.create(lobby_id)
    player_id_one = "player_id_1"
    player_id_two = "player_id_2"

    PlankGames.ConnectFour.Client.join(lobby_id, player_id_one)
    PlankGames.ConnectFour.Client.join(lobby_id, player_id_two)

    {player_id_one, player_id_two}
  end

  test "lookup lobby that exists", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    assert elem(PlankGames.ConnectFour.Client.lookup(lobby_id), 0) == :ok
  end

  test "lookup lobby that does not exist", %{lobby_id: lobby_id} do
    assert elem(PlankGames.ConnectFour.Client.lookup(lobby_id), 0) == :not_found
  end

  test "join lobby", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.ConnectFour.Client.join(lobby_id, player_id) == :ok
    {result, lobby_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    assert result == :ok
    assert Enum.any?(lobby_state.players, fn x -> x.id == player_id end)
  end

  test "join lobby twice same player id", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.ConnectFour.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.ConnectFour.Client.join(lobby_id, player_id) == :already_joined
  end

  test "leave lobby", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.ConnectFour.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.ConnectFour.Client.leave(lobby_id, player_id) == :ok
    {result, lobby_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    assert result == :ok
    assert not Enum.any?(lobby_state.players, fn x -> x.id == player_id end)
  end

  test "leave lobby not a player", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.ConnectFour.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.ConnectFour.Client.leave(lobby_id, "not_a_player") == :not_player
  end

  test "start game", %{lobby_id: lobby_id} do
    start_game(lobby_id)

    {result, lobby_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    assert result == :ok
    assert lobby_state.has_started?
  end

  test "make a valid move", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    assert PlankGames.ConnectFour.Client.move(lobby_id, initial_state.current_player.id, 0) == :ok

    {:ok, state_after_move} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    assert state_after_move.current_player.id != initial_state.current_player.id
  end

  test "make a invalid move", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    assert PlankGames.ConnectFour.Client.move(lobby_id, initial_state.current_player.id, 80) ==
             :invalid_move
  end

  test "make a move when game not started", %{lobby_id: lobby_id} do
    PlankGames.ConnectFour.create(lobby_id)
    player_id = "player_id_1"

    PlankGames.ConnectFour.Client.join(lobby_id, player_id)

    assert PlankGames.ConnectFour.Client.move(lobby_id, player_id, 80) == :not_started
  end

  test "make a move when not player turn", %{lobby_id: lobby_id} do
    {player_id_one, player_id_two} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    player_id =
      case initial_state.current_player.id == player_id_one do
        true -> player_id_two
        false -> player_id_one
      end

    assert PlankGames.ConnectFour.Client.move(lobby_id, player_id, 80) == :not_turn
  end

  test "player win bottom row far left", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_two)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_three)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win bottom row far right", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_seven)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_seven)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_six)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_five)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win center", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_seven)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_one)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)
    PlankGames.ConnectFour.Client.move(lobby_id, state.current_player.id, @column_four)
    {:ok, state} = PlankGames.ConnectFour.Client.lookup(lobby_id)

    assert state.has_finished? == true
    assert state.winner == state.current_player
  end
end
