defmodule PlankGames.ConnectFour.Client do
  require Logger

  def lookup(lobby_id) do
    try do
      {:ok, GenServer.call(via_tuple(lobby_id), :get)}
    catch
      :exit, {:noproc, _} ->
        {:not_found}
    end
  end

  def new(lobby_id, player_id),
    do: GenServer.call(via_tuple(lobby_id), {:new, player_id})

  def join(lobby_id, player_id),
    do: GenServer.call(via_tuple(lobby_id), {:join, player_id})

  def leave(lobby_id, player_id),
    do: GenServer.call(via_tuple(lobby_id), {:leave, player_id})

  def move(lobby_id, player_id, position),
    do: GenServer.call(via_tuple(lobby_id), {:move, player_id, position})

  defp via_tuple(lobby_id),
    do: {:via, Registry, {PlankGames.ConnectFour.LobbyRegistry, "lobby_#{lobby_id}"}}
end
