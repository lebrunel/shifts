defmodule Shifts.SessionTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Session}
  doctest Session

  describe "instruct/4" do
    setup do
      {:ok, session: %Session{shift: :test}}
    end

    test "accepts chore as keyword args", %{session: session} do
      session = Session.instruct(session, :test, "input", task: "test", output: "test")
      assert MapSet.size(session.names) == 1
      assert MapSet.member?(session.names, :test)
      assert length(session.instructions) == 1
      assert {:chore, :test, "input", %Chore{}} = hd(session.instructions)
    end

    test "accepts chore as Chore struct", %{session: session} do
      session = Session.instruct(session, :test, "input", Chore.new(task: "test", output: "test"))
      assert {:chore, :test, "input", %Chore{}} = hd(session.instructions)
    end

    test "accepts input as a callback", %{session: session} do
      session = Session.instruct(session, :test, & &1.foo, task: "test", output: "test")
      assert {:chore, :test, callback, %Chore{}} = hd(session.instructions)
      assert is_function(callback, 1)
    end

    test "raises if input is not string or function", %{session: session} do
      assert_raise FunctionClauseError, fn ->
        Session.instruct(session, :test, :atom, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Session.instruct(session, :test, 31337, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Session.instruct(session, :test, %{foo: :bar}, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Session.instruct(session, :test, ["foo", "bar"], task: "test", output: "test")
      end
    end

    test "raises if chore is invalid", %{session: session} do
      assert_raise NimbleOptions.ValidationError, fn ->
        Session.instruct(session, :test, "input", [])
      end
    end

    test "chains of chore instructions", %{session: session} do
      session =
        session
        |> Session.instruct(:test1, "input", task: "test", output: "test")
        |> Session.instruct(:test2, "input", task: "test", output: "test")

      assert MapSet.size(session.names) == 2
      assert Enum.all?([:test1, :test2], & MapSet.member?(session.names, &1))
      assert length(session.instructions) == 2
      assert {:chore, :test2, "input", %Chore{}} = hd(session.instructions)
    end

    test "raises if instruction name is duplicate", %{session: session} do
      assert_raise RuntimeError, fn ->
        session
        |> Session.instruct(:test, "input", task: "test", output: "test")
        |> Session.instruct(:test, "input", task: "test", output: "test")
      end
    end
  end

  describe "parallel/3" do
    setup do
      {:ok, session: %Session{shift: :test}}
    end

    test "acceps parallel sets of instructions", %{session: session} do
      session =
        session
        |> Session.parallel(:test, 1..2, fn session, i ->
          session
          |> Session.instruct({:a, i}, "input", task: "test", output: "test")
          |> Session.instruct({:b, i}, "input", task: "test", output: "test")
        end)

      assert session.scope == []
      assert MapSet.size(session.names) == 5

      [:test, {:a, 1}, {:a, 2}, {:b, 1}, {:b, 2}]
      |> Enum.all?(& MapSet.member?(session.names, &1))
      |> assert()

      assert length(session.instructions) == 1
      assert {:parallel, :test, [set2, set1]} = hd(session.instructions)
      assert {:chore, {:b, 1}, "input", %Chore{}} = hd(set1)
      assert {:chore, {:b, 2}, "input", %Chore{}} = hd(set2)
    end

    test "acceps nested parallel sets of instructions", %{session: session} do
      session =
        session
        |> Session.parallel(:test, 1..2, fn session, i ->
          Session.parallel(session, {:nested, i}, 1..2, fn session, n ->
            session
            |> Session.instruct({:a, i, n}, "input", task: "test", output: "test")
          end)
        end)

      assert session.scope == []
      assert MapSet.size(session.names) == 7

      [:test, {:nested, 1}, {:nested, 2}, {:a, 1, 1}, {:a, 2, 2}, {:a, 2, 1}, {:a, 2, 2}]
      |> Enum.all?(& MapSet.member?(session.names, &1))
      |> assert()
    end

  end

end
