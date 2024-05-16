defmodule Shifts.ChoreTest do
  use ExUnit.Case, async: true
  alias Shifts.Chore
  doctest Chore

  describe "new/1" do
    test "creates a chore with valid opts" do
      assert %Chore{} = Chore.new(task: "test", output: "test")
    end

    test "raises with invalid opts" do
      assert_raise NimbleOptions.ValidationError, fn -> Chore.new() end
    end
  end

  describe "to_prompt/1" do
    test "returns prompt string with just task" do
      prompt = Chore.to_prompt(Chore.new(task: "a"))
      assert String.match?(prompt, ~r/^a$/)
    end

    test "returns full prompt string" do
      prompt = Chore.to_prompt(Chore.new(task: "a", output: "b", context: "c"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+\nc\n\nThis is.+b$/)
    end

    test "returns prompt string without output" do
      prompt = Chore.to_prompt(Chore.new(task: "a", context: "c"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+\nc$/)
    end

    test "returns prompt string without context" do
      prompt = Chore.to_prompt(Chore.new(task: "a", output: "b"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+b$/)
    end
  end

end
