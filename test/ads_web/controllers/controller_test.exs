defmodule ADSWeb.ControllerTest do
  use ADSWeb.ConnCase

  test "GET / display main layout page", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Algorithms and Data Structures"
  end
end
