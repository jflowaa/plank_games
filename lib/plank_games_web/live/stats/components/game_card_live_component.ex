defmodule PlankGamesWeb.Stats.GameCardLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="block p-6 my-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-sm" style="width: 100%;">
      <h3 class="text-gray-900 leading-tight font-medium mb-2 dark:text-white"><%= @name %></h3>
      <p class="text-gray-700 text-base dark:text-gray-400">Connected Users: <%= Map.get(@stats, :connections) %></p>
      <p class="text-gray-700 text-base mb-4 dark:text-gray-400">Active Games: <%= Map.get(@stats, :games) %></p>
      <a href={"/#{@lobby_url}"}>
        <button type="button" class="text-blue-400
          text-xs
          leading-tight
          focus:text-blue-700
          transition duration-300 ease-in-out">Go to lobbies</button>
      </a>
    </div>
    """
  end
end
