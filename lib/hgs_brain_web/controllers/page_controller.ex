defmodule HgsBrainWeb.PageController do
  use HgsBrainWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
