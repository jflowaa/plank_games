defmodule PlankGamesWeb.Yahtzee.DiceLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>
      <%= if @is_player do %>
        <button phx-click="roll" class="button-small">roll</button>
      <% end %>
      Roll Count <%= @roll_count %>
      <%= render_dice_column(@dice, assigns) %>
    </div>
    """
  end

  defp render_dice_column(dice, assigns) do
    ~H"""
    <div class="column">
      <%= for die <- dice do %>
        <div class="die">
          <span class={"dice dice-#{Map.get(elem(die, 1), :value)}"}
           title={"Dice #{Map.get(elem(die, 1), :value)}"}
           style={"font-size: 4em;margin-right: 10px;cursor: #{if @roll_count > 0, do: "pointer", else: ""}"}
           phx-click={if Map.get(elem(die, 1), :hold), do: "release", else: "hold"}
           phx-value-die={"#{elem(die, 0)}"}/>
           <%= if Map.get(elem(die, 1), :hold) do %>
            <span class="gg-lock" title="Holding"/>
           <% end %>
        </div>
        &nbsp;
      <% end %>
    </div>
    """
  end
end
