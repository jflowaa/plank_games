defmodule PlankGamesWeb.Components.Lobby do
  use Phoenix.Component

  def listing(assigns) do
    ~H"""
    <div class="grid gap-4 md:grid-cols-2">
      <div>
        <h1 class="font-thin text-3xl dark:text-white">Lobbies</h1>
        <%= for lobby <- @lobbies do %>
          <.card id={"#{lobby.id}"} game="tic_tac_toe" lobby={lobby} />
        <% end %>
      </div>
    </div>
    """
  end

  def card(assigns) do
    ~H"""
    <div class="max-w-sm rounded overflow-hidden shadow-lg bg-white dark:bg-gray-800">
      <div class="px-6 py-4">
        <div class="font-bold text-xl mb-2 text-gray-900 dark:text-white">
          Lobby Name: <%= elem(@lobby, 0) %>
        </div>
        <p class="text-base text-gray-700 dark:text-gray-400">
          Connected Users: <%= elem(@lobby, 1) %>
          <a href={"/#{@game}/#{elem(@lobby, 0)}"}>
            <button class="btn-primary">Join Lobby</button>
          </a>
        </p>
      </div>
    </div>
    """
  end

  def new_lobby(assigns) do
    ~H"""
    <div class="flex justify-center">
      <a href={"/#{@game}/#{UUID.uuid4()}"}>
        <button class="btn-primary">New Lobby</button>
      </a>
    </div>
    """
  end

  def failed_to_start(assigns) do
    ~H"""
    <div class="flex justify-center items-center">
      <section class="bg-white
      dark:bg-gray-800
      w-4/5 rounded-lg
      px-6
      py-14
      my-16
      ring-1
      ring-slate-900/5
      shadow-xl
      text-slate-900
      dark:text-white
      text-center">
        <h1 class="font-thin text-3xl">Failed to start lobby</h1>
        <p class="text-slate-500 dark:text-slate-400 mt-2 text-lg">
          Try refreshing the page
        </p>
      </section>
    </div>
    """
  end

  def lobby_chat(assigns) do
    ~H"""
    <div
      class="bg-white
      dark:bg-gray-800
      rounded-lg
      ring-slate-900/5
      shadow-xl
      text-slate-900
      dark:text-white
      relative
      h-[29rem]"
      phx-update="stream"
      id="chat-message-box"
    >
      <%= for {_id, message} <- @messages do %>
        <div class="px-1 py-1">
          <div class="flex gap-3">
            <div class="text-sm p-5 bg-slate-600 text-slate-100 rounded-lg">
              <p><%= message.body %></p>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def control_panel(assigns) do
    assigns =
      assigns
      |> assign_new(:extra_buttons, fn -> nil end)
      |> assign_new(:extra_text, fn -> nil end)

    ~H"""
    <div>
      <div class="text-center">
        <%= if @player_name do %>
          <p class="font-thin text-sm dark:text-white">Player name: <%= @player_name %></p>
        <% end %>
        <p class="font-thin text-lg py-5 dark:text-white">
          Connected Players: <%= @total_players %>
          <br /> <span class="text-sm">Total Connections: <%= @total_connections %></span>
        </p>
        <%= if @extra_buttons do %>
          <%= render_slot(@extra_buttons) %>
        <% end %>
        <%= if @show_join do %>
          <button phx-click="join" class="btn-primary">Join Game</button>
        <% end %>
        <%= if @is_player and not @has_finished do %>
          <button phx-click="leave" class="btn-primary">Leave Game</button>
        <% end %>
        <%= if @is_player and @has_finished do %>
          <button phx-click="new" class="btn-primary">New Game</button>
        <% end %>
        <a href={"/#{@game}"}>
          <button class="btn-primary">Leave Lobby</button>
        </a>
        <%= if @has_started do %>
          <h2 class="font-thin text-xl dark:text-white">Current Player: <%= @current_player %></h2>
        <% end %>
        <%= if @extra_text do %>
          <%= render_slot(@extra_text) %>
        <% end %>
      </div>
    </div>
    """
  end
end
