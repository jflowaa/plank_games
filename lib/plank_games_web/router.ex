defmodule PlankGamesWeb.Router do
  use PlankGamesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PlankGamesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :add_player_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlankGamesWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/tic_tac_toe", TicTacToe.OverviewLive, :index
    live "/tic_tac_toe/:lobby_id", PlankGames.TicTacToe.LobbyLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlankGamesWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:plank_games, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PlankGamesWeb.Telemetry
    end
  end

  defp add_player_id(conn, _opts) do
    if is_nil(get_session(conn, :player_id)) do
      conn
      |> put_session(:player_id, UUID.uuid4())
    else
      conn
    end
  end
end
