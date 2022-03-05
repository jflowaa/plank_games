defmodule PlankGamesWeb.Router do
  use PlankGamesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PlankGamesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :add_player_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlankGamesWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/tictactoe", TicTacToeLive, :index
    live "/tictactoe/:lobby_id", TicTacToeLobbyLive, :index
    live "/connectfour", ConnectFourLive, :index
    live "/connectfour/:lobby_id", ConnectFourLobbyLive, :index
    live "/yahtzee", YahtzeeLive, :index
    live "/yahtzee/:lobby_id", YahtzeeLobbyLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlankGamesWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PlankGamesWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
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
