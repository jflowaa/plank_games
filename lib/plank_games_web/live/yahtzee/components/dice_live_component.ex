defmodule PlankGamesWeb.DiceLiveComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>
      <%= if @is_player do %>
        <button phx-click="roll" class="button-small">roll</button>
      <% end %>
      Roll Count <%= @roll_count %>
      <%= render_dice_column(Enum.take(@dice, 3)) %>
      <%= render_dice_column(Enum.take(Enum.reverse(@dice), 3)) %>
    </div>
    """
  end

  defp render_dice_column(dice, assigns \\ %{}) do
    ~H"""
    <div class="column">
      <%= for die <- dice do %>
        Value: <%= Map.get(elem(die, 1), :value) %>
        Held: <%= Map.get(elem(die, 1), :hold) %>
        <button phx-click={if Map.get(elem(die, 1), :hold), do: "release", else: "hold"} phx-value-die={"#{elem(die, 0)}"} class="button-small">
          <%= if Map.get(elem(die, 1), :hold), do: "Release", else: "Hold" %>
        </button>
      <% end %>
    </div>
    """
  end
end
