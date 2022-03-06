defmodule PlankGamesWeb.ScorecardLiveComponent do
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
        </tbody>
      </table>
    </div>
    """
  end
end
