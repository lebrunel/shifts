defmodule Shifts.Tools.ReadFileTest do
  use ExUnit.Case
  alias Shifts.Tools.ReadFile
  alias Shifts.Tool
  doctest ReadFile

  setup do
    {:ok, tool: ReadFile.to_tool()}
  end

  test "returns the contents of a file", %{tool: tool} do
    res = Tool.invoke(tool, %{file_path: "test/support/test_file.txt"})
    assert res == "Hello world!"
  end

  test "returns error for unknown file", %{tool: tool} do
    res = Tool.invoke(tool, %{file_path: "nofile.txt"})
    assert String.match?(res, ~r/^File\.Error.+no such file or directory$/)
  end

end
