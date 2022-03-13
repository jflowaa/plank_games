defmodule PlankGamesWeb.Live.Common.LobbyPanelComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:extra_buttons, fn -> nil end)
      |> assign_new(:extra_text, fn -> nil end)

    ~H"""
      <div>
        <div class="text-center">
          <p class="font-thin text-lg py-5 dark:text-white">Connected Users: <%= @connection_count %></p>
          <%= if @extra_buttons do %>
            <%= render_slot(@extra_buttons) %>
          <% end %>
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
          <%= if @player_name do %>
            <h2 class="font-thin text-lg dark:text-white">You: <%= @player_name %></h2>
          <% end %>
          <%= if @has_started do %>
            <h2 class="font-thin text-xl dark:text-white">Current Player: <%= @current_player %></h2>
          <% end %>
          <%= if @extra_text do %>
            <%= render_slot(@extra_text) %>
          <% end %>
        </div>
        <.live_component module={PlankGamesWeb.Live.Common.MessageComponent} id="message" messages={@messages} />
      </div>
    """
  end
end
