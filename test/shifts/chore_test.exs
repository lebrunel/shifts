defmodule Shifts.ChoreTest do
  use ExUnit.Case, async: true
  alias Shifts.Worker
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
      tool = Tool.new(name: "test", description: "test", function: fn _job, _args -> "test" end)
      assert %Chore{tools: tools} = Chore.new(task: "test", output: "test", tools: [tool, TestTool])
      assert length(tools) == 2
    end

    test "raises with invalid tool" do
      assert_raise NimbleOptions.ValidationError, ~r/implements the Tool behaviour/, fn ->
        Chore.new(task: "test", output: "test", tools: [NotATool])
      end
    end
  end

  describe "to_prompt/2" do
    test "returns prompt string with input" do
      prompt =
        Chore.new(task: "a", output: "b")
        |> Chore.to_prompt("x")

      assert String.match?(prompt, ~r/^a\n\nInput: x\n\nThis is.+b$/s)
    end

    test "returns prompt string without input" do
      prompt =
        Chore.new(task: "a", output: "b")
        |> Chore.to_prompt()

      assert String.match?(prompt, ~r/^a\n\nThis is.+b$/s)
    end

    test "returns worker system prompt" do
      prompt =
        Chore.new(task: "a", output: "b", worker: Worker.new(role: "a", goal: "b"))
        |> Chore.to_prompt(:system)

      assert String.match?(prompt, ~r/^Your role/s)
    end

    test "returns no system prompt without worker" do
      prompt =
        Chore.new(task: "a", output: "b")
        |> Chore.to_prompt(:system)

      assert is_nil(prompt)
    end
  end

end
