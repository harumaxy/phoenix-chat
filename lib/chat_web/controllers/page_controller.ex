defmodule ChatWeb.PageController do
  use ChatWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/chat")
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)
  end
end
