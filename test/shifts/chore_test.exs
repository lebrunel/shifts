defmodule Shifts.ChoreTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Tool, Worker}
  doctest Chore

  describe "new/1" do
    test "creates a chore with valid opts" do
      assert %Chore{} = Chore.new(task: "a")
    end

    test "raises with invalid opts" do
      assert_raise NimbleOptions.ValidationError, fn -> Chore.new() end
    end

    test "accepts a list of tool structs or modules" do
      tools = [Tool.new(name: "a", description: "b", function: fn _a -> "c" end), TestTool]
      assert %Chore{} = chore = Chore.new(task: "a", tools: tools)
      assert length(chore.tools) == 2
      assert Enum.all?(chore.tools, & match?(%Tool{}, &1))
    end

    test "raises with invalid tool" do
      assert_raise NimbleOptions.ValidationError, ~r/implements the Tool behaviour/, fn ->
        Chore.new(task: "a", tools: [NotATool])
      end
    end
  end

  describe "get_prompt/1" do
    test "returns prompt string with just task" do
      prompt = Chore.get_prompt(Chore.new(task: "a"))
      assert String.match?(prompt, ~r/^a$/)
    end

    test "returns full prompt string" do
      prompt = Chore.get_prompt(Chore.new(task: "a", output: "b", context: "c"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+\nc\n\nThis is.+b$/)
    end

    test "returns prompt string without output" do
      prompt = Chore.get_prompt(Chore.new(task: "a", context: "c"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+\nc$/)
    end

    test "returns prompt string without context" do
      prompt = Chore.get_prompt(Chore.new(task: "a", output: "b"))
      assert String.match?(prompt, ~r/^a\n\nThis is.+b$/)
    end
  end

  describe "init_chat/1" do
    test "returns chat without worker, tools or llm" do
      chore = Chore.new(task: "a")
      chat = Chore.init_chat(chore)
      assert is_nil(chat.system)
      assert Enum.empty?(chat.tools)
      refute is_nil(chat.llm)
    end

    test "returns chat with worker" do
      chore = Chore.new(task: "a", worker: Worker.new(role: "a", goal: "b"))
      chat = Chore.init_chat(chore)
      assert is_binary(chat.system)
    end

  end

end
