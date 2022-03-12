defmodule PlankGamesWeb.Live.Common.LobbyPanelComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
      <div>
        <div class="text-center">
          <p class="font-thin text-lg py-5 dark:text-white">Connected Users: <%= @connection_count %></p>
          <%= if @show_join do %>
            <button phx-click="join" class="btn-primary" >Join Game</button>
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
          <%= if @player_token do %>
            <h2 class="font-thin text-lg py-5 dark:text-white">Your Token: <%= @player_token %></h2>
          <% end %>
          <%= if @has_started do %>
            <h2 class="font-thin text-xl py-5 dark:text-white">Current Turn: <%= @current_token %></h2>
          <% end %>
        </div>
        <.live_component module={PlankGamesWeb.Live.Common.MessageComponent} id="message" messages={@messages} />
      </div>
    """
  end
end
