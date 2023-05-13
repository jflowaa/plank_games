defmodule PlankGamesWeb.Live.Common.MessageComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
      <div class="block p-6 my-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-sm container mx-auto">
        <%= for message <- @messages do %>
          <span class="text-gray-700 mb-4 dark:text-white text-sm"><%= message %></span><br/>
        <% end %>
      </div>
    """
  end
end
