defmodule Shifts.JobTest do
  use ExUnit.Case, async: true
  alias Shifts.{Chore, Job}
  doctest Job

  describe "chore/4" do
    setup do
      {:ok, job: %Job{shift: :test}}
    end

    test "accepts chore as keyword args", %{job: job} do
      job = Job.chore(job, :test, "input", task: "test", output: "test")
      assert length(job.operations) == 1
      assert {:test, {%Chore{}, "input"}} = hd(job.operations)
    end

    test "accepts chore as Chore struct", %{job: job} do
      job = Job.chore(job, :test, "input", Chore.new(task: "test", output: "test"))
      assert {:test, {%Chore{}, "input"}} = hd(job.operations)
    end

    test "accepts input as an atom", %{job: job} do
      job = Job.chore(job, :test, :foo, task: "test", output: "test")
      assert {:test, {%Chore{}, :foo}} = hd(job.operations)
    end

    test "accepts input as a callback", %{job: job} do
      job = Job.chore(job, :test, & &1.foo, task: "test", output: "test")
      assert {:test, {%Chore{}, callback}} = hd(job.operations)
      assert is_function(callback, 1)
    end

    test "raises if input is not string, atom or function", %{job: job} do
      assert_raise FunctionClauseError, fn ->
        Job.chore(job, :test, 31337, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Job.chore(job, :test, %{foo: :bar}, task: "test", output: "test")
      end
      assert_raise FunctionClauseError, fn ->
        Job.chore(job, :test, ["foo", "bar"], task: "test", output: "test")
      end
    end

    test "raises if chore is invalid", %{job: job} do
      assert_raise NimbleOptions.ValidationError, fn ->
        Job.chore(job, :test, "input", [])
      end
    end

    test "chains of chore instructions", %{job: job} do
      job =
        job
        |> Job.chore(:test1, "input", task: "test", output: "test")
        |> Job.chore(:test2, "input", task: "test", output: "test")

      assert length(job.operations) == 2
      assert {:test2, {%Chore{}, "input"}} = hd(job.operations)
    end

    test "raises if instruction name is duplicate", %{job: job} do
      assert_raise RuntimeError, fn ->
        job
        |> Job.chore(:test, "input", task: "test", output: "test")
        |> Job.chore(:test, "input", task: "test", output: "test")
      end
    end
  end


  describe "each/4" do
    setup do
      {:ok, job: %Job{shift: :test}}
    end

    test "creates parallel sets of child jobs", %{job: job} do
      job =
        job
        |> Job.each(:test, 1..2, fn job, _i ->
          job
          |> Job.chore(:a, "input", task: "test", output: "test")
          |> Job.chore(:b, "input", task: "test", output: "test")
        end)

      assert length(job.operations) == 1
      assert {:test, {:each, [child | _] = jobs}} = hd(job.operations)
      assert length(jobs) == 2
      assert length(child.operations) == 2
      assert {:b, {%Chore{}, "input"}} = hd(child.operations)
    end

    test "creates nests sets of child jobs", %{job: job} do
      job =
        job
        |> Job.chore(:test, "input", task: "test", output: "test")
        |> Job.each(:children, 1..2, fn job, _i ->
          job
          |> Job.chore(:test, "input", task: "test", output: "test")
          |> Job.each(:children, 1..2, fn job, _i ->
            Job.chore(job, :test, "input", task: "test", output: "test")
          end)
        end)

      assert length(job.operations) == 2
      assert {:children, {:each, [child | _] = jobs}} = hd(job.operations)
      assert length(jobs) == 2
      assert length(child.operations) == 2
      assert {:children, {:each, [child | _] = jobs}} = hd(child.operations)
      assert length(jobs) == 2
      assert length(child.operations) == 1
      assert {:test, {%Chore{}, "input"}} = hd(child.operations)
    end
  end

end
