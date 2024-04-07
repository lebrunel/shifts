defmodule Shifts.ChoreTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Tool}
  doctest Chore

  describe "new/1" do
    test "creates a chore with valid opts" do
      assert %Chore{} = Chore.new(task: "test", output: "test")
    end

    test "raises with invalid opts" do
      assert_raise NimbleOptions.ValidationError, fn -> Chore.new() end
    end

    test "accepts a list of tool structs or modules" do
      tool = Tool.new(name: :test, description: "test", function: fn _job, _args -> "test" end)
      assert %Chore{tools: tools} = Chore.new(task: "test", output: "test", tools: [tool, TestTool])
      assert length(tools) == 2
    end
  end

end
