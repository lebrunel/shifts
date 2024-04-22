defmodule Shifts.Tools.ReadDirectoryTest do
  use ExUnit.Case
  alias Shifts.Tools.ReadDirectory
  alias Shifts.Tool
  doctest ReadDirectory

  setup do
    {:ok, tool: ReadDirectory.to_tool()}
  end

  test "returns a list of files", %{tool: tool} do
    res = Tool.execute(tool, %{directory: "test"})
    assert String.match?(res, ~r/File paths:\n- test\/shifts/)
  end

  test "returns error for unknown dir", %{tool: tool} do
    res = Tool.execute(tool, %{directory: "nodir"})
    assert String.match?(res, ~r/^File\.Error.+no such file or directory$/)
  end

end
