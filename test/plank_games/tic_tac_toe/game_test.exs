defmodule PlankGames.TicTacToe.GameTest do
  use ExUnit.Case, async: true

  @top_left_pos 0
  @top_center_pos 1
  @top_right_pos 2
  @mid_left_pos 3
  @mid_center_pos 4
  @mid_right_pos 5
  @bottom_left_pos 6
  @bottom_center_pos 7
  @bottom_right_pos 8

  setup do
    start_supervised(PlankGames.TicTacToe)

    [lobby_id: UUID.uuid4()]
  end

  def start_game(lobby_id) do
    PlankGames.TicTacToe.create(lobby_id)
    player_id_one = "player_id_1"
    player_id_two = "player_id_2"

    PlankGames.TicTacToe.Client.join(lobby_id, player_id_one)
    PlankGames.TicTacToe.Client.join(lobby_id, player_id_two)

    {player_id_one, player_id_two}
  end

  test "lookup lobby that exists", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    assert elem(PlankGames.TicTacToe.Client.lookup(lobby_id), 0) == :ok
  end

  test "lookup lobby that does not exist", %{lobby_id: lobby_id} do
    assert elem(PlankGames.TicTacToe.Client.lookup(lobby_id), 0) == :not_found
  end

  test "join lobby", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.TicTacToe.Client.join(lobby_id, player_id) == :ok
    {result, lobby_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert result == :ok
    assert Enum.any?(lobby_state.players, fn x -> x.id == player_id end)
  end

  test "join lobby twice same player id", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.TicTacToe.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.TicTacToe.Client.join(lobby_id, player_id) == :already_joined
  end

  test "leave lobby", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.TicTacToe.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.TicTacToe.Client.leave(lobby_id, player_id) == :ok
    {result, lobby_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert result == :ok
    assert not Enum.any?(lobby_state.players, fn x -> x.id == player_id end)
  end

  test "leave lobby not a player", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    player_id = "player_id_1"

    assert PlankGames.TicTacToe.Client.join(lobby_id, player_id) == :ok
    assert PlankGames.TicTacToe.Client.leave(lobby_id, "not_a_player") == :not_player
  end

  test "start game", %{lobby_id: lobby_id} do
    start_game(lobby_id)

    {result, lobby_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert result == :ok
    assert lobby_state.has_started?
  end

  test "make a valid move", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)

    assert PlankGames.TicTacToe.Client.move(lobby_id, initial_state.current_player.id, 0) == :ok

    {:ok, state_after_move} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state_after_move.current_player.id != initial_state.current_player.id
  end

  test "make a invalid move", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)

    assert PlankGames.TicTacToe.Client.move(lobby_id, initial_state.current_player.id, 80) ==
             :invalid_move
  end

  test "make a move when game not started", %{lobby_id: lobby_id} do
    PlankGames.TicTacToe.create(lobby_id)
    player_id = "player_id_1"

    PlankGames.TicTacToe.Client.join(lobby_id, player_id)

    assert PlankGames.TicTacToe.Client.move(lobby_id, player_id, 80) == :not_started
  end

  test "make a move when not player turn", %{lobby_id: lobby_id} do
    {player_id_one, player_id_two} = start_game(lobby_id)

    {:ok, initial_state} = PlankGames.TicTacToe.Client.lookup(lobby_id)

    player_id =
      case initial_state.current_player.id == player_id_one do
        true -> player_id_two
        false -> player_id_one
      end

    assert PlankGames.TicTacToe.Client.move(lobby_id, player_id, 80) == :not_turn
  end

  test "player win top row", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win middle row", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win bottom row", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win left diagonal", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "player win right diagonal", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert state.has_finished? == true
    assert state.winner == state.current_player
  end

  test "new game players auto join", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @bottom_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)

    assert PlankGames.TicTacToe.Client.new(lobby_id, state.current_player.id) == :ok
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    assert Enum.count(state.players) == 2
    assert state.has_started?
  end

  test "new game not finished", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)

    assert PlankGames.TicTacToe.Client.new(lobby_id, state.current_player.id) == :not_finished
  end

  test "new game not player", %{lobby_id: lobby_id} do
    {_, _} = start_game(lobby_id)

    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_right_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_left_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @mid_center_pos)
    {:ok, state} = PlankGames.TicTacToe.Client.lookup(lobby_id)
    PlankGames.TicTacToe.Client.move(lobby_id, state.current_player.id, @top_left_pos)

    assert PlankGames.TicTacToe.Client.new(lobby_id, "not-real-id") == :not_player
  end
end
