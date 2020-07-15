defmodule EspyWeb.PageController do
  use EspyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
