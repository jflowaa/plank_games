defmodule PlankGamesWeb.Yahtzee.DiceLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="block p-6 my-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-md">
      <%= if @is_player do %>
        <button phx-click="roll" class="btn-primary">Roll</button>
      <% end %>
      <p class="text-gray-700 text-base mb-4 dark:text-white text-sm"> Roll Count <%= @roll_count %></p>
      <%= render_dice_column(@dice, assigns) %>
    </div>
    """
  end

  defp render_dice_column(dice, assigns) do
    ~H"""
    <div class="flex justify-center">
      <%= for die <- dice do %>
        <div class="die">
          <span class={"dice text-3xl md:text-5xl mx-1 dice-#{Map.get(elem(die, 1), :value)} #{if @roll_count > 0, do: "cursor-pointer"}"}
           title={"Dice #{Map.get(elem(die, 1), :value)}"}
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
