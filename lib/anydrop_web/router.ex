defmodule AnydropWeb.Router do
  use AnydropWeb, :router

  import AnydropWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AnydropWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AnydropWeb do
    pipe_through :browser

    live_session :mount_user,
        on_mount: [{AnydropWeb.UserAuth, :mount_current_user}] do
          live "/", HomeLive
          live "/9a2ba138ad23cf439dc6b82696ab5a645cdbec18", AdminLive
          # live "/drops", AdminLive
      end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AnydropWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:anydrop, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AnydropWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AnydropWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AnydropWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register/:token", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  # scope "/", AnydropWeb do
  #   pipe_through [:browser, :require_authenticated_user]

  #   live_session :require_authenticated_user,
  #     on_mount: [{AnydropWeb.UserAuth, :ensure_authenticated}] do

  #   end
  # end

  scope "/", AnydropWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    # live_session :current_user,
    #   on_mount: [{AnydropWeb.UserAuth, :mount_current_user}] do

    # end
  end
end
