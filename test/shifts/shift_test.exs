defmodule Shifts.ShiftTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Shift}
  doctest Shift

  describe "task/3" do
    setup do
      {:ok, shift: %Shift{}}
    end

    test "accepts chore as keyword args", %{shift: shift} do
      shift = Shift.task(shift, :test, task: "test", output: "test")
      assert length(shift.operations) == 1
      assert {:test, {:task, %Chore{}}} = hd(shift.operations)
    end

    test "accepts chore as Chore struct", %{shift: shift} do
      shift = Shift.task(shift, :test, Chore.new(task: "test", output: "test"))
      assert {:test, {:task, %Chore{}}} = hd(shift.operations)
    end

    test "accepts chore as a callback", %{shift: shift} do
      shift = Shift.task(shift, :test, fn _ -> Chore.new(task: "test", output: "test") end)
      assert {:test, {:task, callback}} = hd(shift.operations)
      assert is_function(callback, 1)
    end

    test "raises if chore is invalid", %{shift: shift} do
      assert_raise NimbleOptions.ValidationError, fn ->
        Shift.task(shift, :test, [])
      end
    end

    test "chains of chore instructions", %{shift: shift} do
      shift =
        shift
        |> Shift.task(:test1, task: "test", output: "test")
        |> Shift.task(:test2, task: "test", output: "test")

      assert length(shift.operations) == 2
      assert {:test2, {:task, %Chore{}}} = hd(shift.operations)
    end

    test "raises if instruction name is duplicate", %{shift: shift} do
      assert_raise RuntimeError, fn ->
        shift
        |> Shift.task(:test, task: "test", output: "test")
        |> Shift.task(:test, task: "test", output: "test")
      end
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
          |> Shift.task(:a, task: "test", output: "test")
          |> Shift.task(:b, task: "test", output: "test")
        end)

      assert length(shift.operations) == 1
      assert {:test, {:each, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:b, {:task, %Chore{}}} = hd(child.operations)
    end

    test "creates nested sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.task(:test, task: "test", output: "test")
        |> Shift.each(:children, 1..2, fn shift, _i ->
          shift
          |> Shift.task(:test, task: "test", output: "test")
          |> Shift.each(:children, 1..2, fn shift, _i ->
            Shift.task(shift, :test, task: "test", output: "test")
          end)
        end)

      assert length(shift.operations) == 2
      assert {:children, {:each, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:children, {:each, [child | _] = shifts}} = hd(child.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 1
      assert {:test, {:task, %Chore{}}} = hd(child.operations)
    end
  end

  describe "each_async/4" do
    setup do
      {:ok, shift: %Shift{}}
    end

    test "creates parallel sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.each_async(:test, 1..2, fn shift, _i ->
          shift
          |> Shift.task(:a, task: "test", output: "test")
          |> Shift.task(:b, task: "test", output: "test")
        end)

      assert length(shift.operations) == 1
      assert {:test, {:each_async, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:b, {:task, %Chore{}}} = hd(child.operations)
    end

    test "creates nested sets of child shifts", %{shift: shift} do
      shift =
        shift
        |> Shift.task(:test, task: "test", output: "test")
        |> Shift.each_async(:children, 1..2, fn shift, _i ->
          shift
          |> Shift.task(:test, task: "test", output: "test")
          |> Shift.each_async(:children, 1..2, fn shift, _i ->
            Shift.task(shift, :test, task: "test", output: "test")
          end)
        end)

      assert length(shift.operations) == 2
      assert {:children, {:each_async, [child | _] = shifts}} = hd(shift.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 2
      assert {:children, {:each_async, [child | _] = shifts}} = hd(child.operations)
      assert length(shifts) == 2
      assert length(child.operations) == 1
      assert {:test, {:task, %Chore{}}} = hd(child.operations)
    end
  end

end
