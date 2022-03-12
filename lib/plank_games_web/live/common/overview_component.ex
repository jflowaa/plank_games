defmodule PlankGamesWeb.Live.Common.OverviewComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
      <div class="container mx-auto">
        <div class="grid gap-4 md:grid-cols-2">
          <div>
              <h1 class="font-thin text-3xl dark:text-white">Lobbies</h1>
              <%= for lobby <- @lobbies do %>
                <div class="block p-6 my-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-sm">
                  <h3 class="text-gray-900 leading-tight font-medium mb-2 dark:text-white">Lobby Name: <%= elem(lobby, 0) %></h3>
                  <p class="text-gray-700 text-base mb-4 dark:text-gray-400">Connected Users: <%= elem(lobby, 1) %></p>
                  <a href={"/#{@game}/#{elem(lobby, 0)}"}>
                    <button class="btn-primary">Join Lobby</button>
                  </a>
                </div>
              <% end %>
            </div>
          <div class="flex justify-center">
            <a href={"/#{@game}/#{UUID.uuid4()}"}>
              <button class="btn-primary">New Lobby</button>
            </a>
          </div>
        </div>
      </div>
    """
  end
end
