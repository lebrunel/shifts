defmodule Shifts.WorkerTest do
  use ExUnit.Case, async: true
  alias Shifts.{Worker}
  doctest Worker

  describe "new/1" do
    test "creates a worker with valid params" do
      assert %Worker{} = Worker.new(role: "a", goal: "b")
    end

    test "raises with invalid params" do
      assert_raise NimbleOptions.ValidationError, fn -> Worker.new() end
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
