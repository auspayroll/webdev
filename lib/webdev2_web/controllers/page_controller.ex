defmodule Webdev2Web.PageController do
  use Webdev2Web, :controller
  plug :put_layout, "page.html"

  def index(conn, _params) do
    render(conn, "index.html")
  end
  
end
