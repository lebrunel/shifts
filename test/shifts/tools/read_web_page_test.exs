defmodule Shifts.Tools.ReadWebPageTest do
  use ExUnit.Case
  import Mock
  alias Shifts.Tools.ReadWebPage
  alias Shifts.Tool
  doctest ReadWebPage

  setup do
    {:ok, tool: ReadWebPage.to_tool()}
  end

  test "returns the contents of web page", %{tool: tool} do
    response = %Req.Response{
      status: 200,
      headers: [
        {"content-type", "text/html; charset=utf-8"}
      ],
      body: """
      <h1>Hello world!</h1>
      <p>Incididunt ut Lorem tempor pariatur minim aliquip ipsum fugiat cillum dolor non. Dolore in consequat tempor in.</p>
      """
    }
    with_mock Req, get!: fn _url -> response end do
      res = Tool.execute(tool, %{url: "http://test.com"})
      assert String.match?(res, ~r/^# Hello world!\n\nIncididunt ut/)
    end
  end

  test "returns error for http error", %{tool: tool} do
    response = %Req.Response{status: 404}
    with_mock Req, get!: fn _url -> response end do
      res = Tool.execute(tool, %{url: "http://test.com"})
      assert String.match?(res, ~r/^HTTPError.+404$/)
    end
  end

end
