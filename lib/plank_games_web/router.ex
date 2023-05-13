defmodule PlankGamesWeb.Router do
  use PlankGamesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PlankGamesWeb.Layouts, :root}
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
    live "/dashboard", Stats.DashboardLive, :index
    live "/tictactoe", TicTacToe.OverviewLive, :index
    live "/tictactoe/:lobby_id", PlankGames.TicTacToe.LobbyLive, :index
    live "/connectfour", ConnectFour.OverviewLive, :index
    live "/connectfour/:lobby_id", PlankGames.ConnectFour.LobbyLive, :index
    live "/yahtzee", Yahtzee.OverviewLive, :index
    live "/yahtzee/:lobby_id", PlankGames.Yahtzee.LobbyLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlankGamesWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:plank_games, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def add_player_id(conn, _opts) do
    if is_nil(get_session(conn, :player_id)) do
      put_session(conn, :player_id, UUID.uuid4())
    else
      conn
    end
  end
end
