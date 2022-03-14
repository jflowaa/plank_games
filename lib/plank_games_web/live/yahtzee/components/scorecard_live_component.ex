defmodule PlankGamesWeb.PlankGames.Yahtzee.ScorecardLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="block p-6 mr-3 mt-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 dark:text-white w-100 shrink-0">
      <h2 class="text-gray-700 dark:text-white text-base mb-4 text-md"><%= elem(@scorecard, 0) %>'s Scorecard</h2>
      <div class="flex flex-col">
        <table class="table-fixed text-xl">
          <thead class="border-b">
            <th scope="col" class="px-4 text-left">Category</th>
            <th scope="col" class="text-left">Score</th>
          </thead>
          <tbody>
            <%= for category <- PlankGames.Yahtzee.Scorecard.get_upper_section() do %>
              <tr>
                <td class="text-md"><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
                <td class={"text-center #{if is_nil(Map.get(elem(@scorecard, 1), category)), do: "cursor-pointer border-b"}"} phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
              </tr>
            <% end %>
            <tr>
              <td class="text-md">Upper section bonus</td>
              <td class="text-center" ><%= Map.get(elem(@scorecard, 1), :upper_section_bonus) %></td>
            </tr>
            <tr>
              <td class="text-md">Upper section</td>
              <td class="text-center" ><%= Map.get(elem(@scorecard, 1), :upper_section) %></td>
            </tr>
            <%= for category <- PlankGames.Yahtzee.Scorecard.get_lower_section() do %>
              <tr>
                <td class="text-md"><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
                <td class={"text-center #{if is_nil(Map.get(elem(@scorecard, 1), category)), do: "cursor-pointer border-b"}"} phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
              </tr>
            <% end %>
            <tr>
              <td class="text-md">Yahtzee bonus</td>
              <%= if Map.get(elem(@scorecard, 1), :yahtzee) == 50 do %>
                <td class="text-center cursor-pointer border-b" phx-click="end_turn" phx-value-category={"yahtzee"}><%= Map.get(elem(@scorecard, 1), :yahtzee_bonus) %></td>
              <% else %>
                <td class="text-center" ><%= Map.get(elem(@scorecard, 1), :yahtzee_bonus) %></td>
              <% end %>
            </tr>
            <tr>
              <td class="text-md">Lower section</td>
              <td class="text-center" ><%= Map.get(elem(@scorecard, 1), :lower_section) %></td>
            </tr>
            <tr>
              <td class="text-md">Grand total</td>
              <td class="text-center"><%= Map.get(elem(@scorecard, 1), :grand_total) %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
