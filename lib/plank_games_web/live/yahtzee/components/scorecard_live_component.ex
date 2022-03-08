defmodule PlankGamesWeb.Yahtzee.ScorecardLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>
      Scorecard
      <table>
        <thead>
          <th>Category</th>
          <th>Score</th>
        </thead>
        <tbody>
          <%= for category <- Yahtzee.Scorecard.get_upper_section() do %>
            <tr>
              <td><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
              <td phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
            </tr>
          <% end %>
          <tr>
            <td>Upper section bonus</td>
            <td><%= Map.get(elem(@scorecard, 1), :upper_section_bonus) %></td>
          </tr>
          <tr>
            <td>Upper section</td>
            <td><%= Map.get(elem(@scorecard, 1), :upper_section) %></td>
          </tr>
          <%= for category <- Yahtzee.Scorecard.get_lower_section() do %>
            <tr>
              <td><%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %></td>
              <td phx-click="end_turn" phx-value-category={"#{category}"}><%= Map.get(elem(@scorecard, 1), category) %></td>
            </tr>
          <% end %>
          <tr>
            <td>Yahtzee bonus</td>
            <td><%= Map.get(elem(@scorecard, 1), :yahtzee_bonus) %></td>
          </tr>
          <tr>
            <td>Lower section</td>
            <td><%= Map.get(elem(@scorecard, 1), :lower_section) %></td>
          </tr>
          <tr>
            <td>Grand total</td>
            <td><%= Map.get(elem(@scorecard, 1), :grand_total) %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
