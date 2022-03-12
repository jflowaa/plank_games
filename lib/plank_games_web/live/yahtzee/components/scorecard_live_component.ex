defmodule PlankGamesWeb.Yahtzee.ScorecardLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="block p-6 my-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-md dark:text-white ">
      <h2 class="text-gray-700 dark:text-white text-base mb-4 text-sm">TODO Player's Name Scorecard</h2>
      <div class="flex flex-col">
        <table class="table-fixed text-sm font-medium">
          <thead class="border-b">
            <th scope="col" class="px-4 py-4 text-left">Category</th>
            <th scope="col" class="px-4 py-4 text-left">Score</th>
          </thead>
          <tbody>
            <%= for category <- Yahtzee.Scorecard.get_upper_section() do %>
              <tr>
                <td class="text-lg"><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
                <td class={"text-left #{if is_nil(Map.get(elem(@scorecard, 1), category)), do: "cursor-pointer border-b"}"} phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
              </tr>
            <% end %>
            <tr>
              <td class="text-lg">Upper section bonus</td>
              <td class="text-left" ><%= Map.get(elem(@scorecard, 1), :upper_section_bonus) %></td>
            </tr>
            <tr>
              <td class="text-lg">Upper section</td>
              <td class="text-left" ><%= Map.get(elem(@scorecard, 1), :upper_section) %></td>
            </tr>
            <%= for category <- Yahtzee.Scorecard.get_lower_section() do %>
              <tr>
                <td class="text-lg"><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
                <td class={"text-left #{if is_nil(Map.get(elem(@scorecard, 1), category)), do: "cursor-pointer border-b"}"} phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
              </tr>
            <% end %>
            <tr>
              <td class="text-lg">Yahtzee bonus</td>
              <td class="text-left" ><%= Map.get(elem(@scorecard, 1), :yahtzee_bonus) %></td>
            </tr>
            <tr>
              <td class="text-lg">Lower section</td>
              <td class="text-left" ><%= Map.get(elem(@scorecard, 1), :lower_section) %></td>
            </tr>
            <tr>
              <td class="text-lg">Grand total</td>
              <td class="text-left"><%= Map.get(elem(@scorecard, 1), :grand_total) %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
