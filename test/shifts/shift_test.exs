defmodule Shifts.ShiftTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Shift}
  doctest Shift

  describe "chore/4" do
    setup do
      {:ok, shift: %Shift{}}
    end

    test "accepts chore as keyword args", %{shift: shift} do
      shift = Shift.chore(shift, :test, "input", task: "test", output: "test")
      assert length(shift.operations) == 1
      assert {:test, {%Chore{}, "input"}} = hd(shift.operations)
    end

    test "accepts chore as Chore struct", %{shift: shift} do
      shift = Shift.chore(shift, :test, "input", Chore.new(task: "test", output: "test"))
      assert {:test, {%Chore{}, "input"}} = hd(shift.operations)
    end

    test "accepts input as an atom", %{shift: shift} do
      shift = Shift.chore(shift, :test, :foo, task: "test", output: "test")
      assert {:test, {%Chore{}, :foo}} = hd(shift.operations)
    end

    test "accepts input as a callback", %{shift: shift} do
      shift = Shift.chore(shift, :test, & &1.foo, task: "test", output: "test")
      assert {:test, {%Chore{}, callback}} = hd(shift.operations)
      assert is_function(callback, 1)
    end

    test "raises if input is not string, atom or function", %{shift: shift} do
      assert_raise FunctionClauseError, fn ->
        Shift.chore(shift, :test, 31337, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Shift.chore(shift, :test, %{foo: :bar}, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Shift.chore(shift, :test, ["foo", "bar"], task: "test", output: "test")
      end
    end

    test "raises if chore is invalid", %{shift: shift} do
      assert_raise NimbleOptions.ValidationError, fn ->
        Shift.chore(shift, :test, "input", [])
      end
    end

    test "chains of chore instructions", %{shift: shift} do
      shift =
        shift
        |> Shift.chore(:test1, "input", task: "test", output: "test")
        |> Shift.chore(:test2, "input", task: "test", output: "test")

      assert length(shift.operations) == 2
      assert {:test2, {%Chore{}, "input"}} = hd(shift.operations)
    end

    test "raises if instruction name is duplicate", %{shift: shift} do
      assert_raise RuntimeError, fn ->
        shift
        |> Shift.chore(:test, "input", task: "test", output: "test")
        |> Shift.chore(:test, "input", task: "test", output: "test")
      end
    end
  end

  describe "async/4" do
    setup do
      {:ok, shift: %Shift{}}
    end

    test "creates parallel sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.async(:test, 1..2, fn shift, _i ->
          shift
          |> Shift.chore(:a, "input", task: "test", output: "test")
          |> Shift.chore(:b, "input", task: "test", output: "test")
        end)

      assert length(shift.operations) == 1
      assert {:test, {:async, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:b, {%Chore{}, "input"}} = hd(child.operations)
    end

    test "creates nested sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.chore(:test, "input", task: "test", output: "test")
        |> Shift.async(:children, 1..2, fn shift, _i ->
          shift
          |> Shift.chore(:test, "input", task: "test", output: "test")
          |> Shift.async(:children, 1..2, fn shift, _i ->
            Shift.chore(shift, :test, "input", task: "test", output: "test")
          end)
        end)

      assert length(shift.operations) == 2
      assert {:children, {:async, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:children, {:async, [child | _] = shifts}} = hd(child.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 1
      assert {:test, {%Chore{}, "input"}} = hd(child.operations)
    end
  end

  describe "each/4" do
    setup do
      {:ok, shift: %Shift{}}
    end

    test "creates parallel sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.each(:test, 1..2, fn shift, _i ->
          shift
          |> Shift.chore(:a, "input", task: "test", output: "test")
          |> Shift.chore(:b, "input", task: "test", output: "test")
        end)

      assert length(shift.operations) == 1
      assert {:test, {:each, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:b, {%Chore{}, "input"}} = hd(child.operations)
    end

    test "creates nested sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.chore(:test, "input", task: "test", output: "test")
        |> Shift.each(:children, 1..2, fn shift, _i ->
          shift
          |> Shift.chore(:test, "input", task: "test", output: "test")
          |> Shift.each(:children, 1..2, fn shift, _i ->
            Shift.chore(shift, :test, "input", task: "test", output: "test")
          end)
        end)

      assert length(shift.operations) == 2
      assert {:children, {:each, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:children, {:each, [child | _] = shifts}} = hd(child.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 1
      assert {:test, {%Chore{}, "input"}} = hd(child.operations)
    end
  end

end
