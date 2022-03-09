defmodule PlankGamesWeb.Common.MessageLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
      <div class="message-box">
        <%= for message <- @messages do %>
          <span><%= message %></span><br/>
        <% end %>
      </div>
    """
  end
end
