defmodule Shifts.WorkerTest do
  use ExUnit.Case, async: true
  alias Shifts.{Worker, Tool}
  doctest Worker

  describe "new/1" do
    test "creates a worker with valid params" do
      assert %Worker{} = Worker.new(role: "a", goal: "b")
    end

    test "raises with invalid params" do
      assert_raise NimbleOptions.ValidationError, fn -> Worker.new() end
    end

    test "accepts tools as struct and modules" do
      tools = [Tool.new(name: "a", description: "b", function: fn _a -> "c" end), TestTool]
      assert %Worker{} = worker = Worker.new(role: "a", goal: "b", tools: tools)
      assert length(worker.tools) == 2
      assert Enum.all?(worker.tools, & match?(%Tool{}, &1))
    end

    test "raises with invalid tool" do
      assert_raise NimbleOptions.ValidationError, ~r/implements the Tool behaviour/, fn ->
        Worker.new(role: "a", goal: "b", tools: [NotATool])
      end
    end
  end

  describe "get_prompt/1" do
    test "returns prompt string with role and goal" do
      prompt = Worker.get_prompt(Worker.new(role: "a", goal: "b", story: "c"))
      assert String.match?(prompt, ~r/^Your role.+a\.\nc\n\nYour.+b$/s)
    end

    test "returns prompt string without story" do
      prompt = Worker.get_prompt(Worker.new(role: "a", goal: "b"))
      assert String.match?(prompt, ~r/^Your role.+a\.\n\nYour.+b$/s)
    end
  end
end
