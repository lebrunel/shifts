defmodule Shifts do
  @moduledoc """
  Documentation for `Shifts`.
  """
  alias Shifts.{Chat, Chore, Job}

  @spec process_job(module(), term()) :: Job.t()
  def process_job(module, input) do
    unless function_exported?(module, :work, 2) do
      # todo - better exception
      raise "not a shift module"
    end

    job = apply(module, :work, [%Job{shift: :test}, input])

    job.operations
    |> Enum.reverse()
    |> Enum.reduce(job, fn {name, operation}, job ->
      chat = process_operation(operation, job)
      update_in(job.results, & Map.put(&1, name, Chat.finalize(chat)))
    end)
  end

  @spec process_operation(Job.operation(), Job.t()) :: Chat.t()
  def process_operation({%Chore{} = chore, input}, %Job{} = job)
    when is_function(input, 1)
  do
    results =
      job.results
      |> Enum.map(fn {key, {val, _chat}} -> {key, val} end)
      |> Enum.into(%{})

    # todo - handle if the input function errors
    process_operation({chore, input.(results)}, job)
  end

  def process_operation({%Chore{} = chore, input}, %Job{} = _job)
    when is_binary(input)
  do
    Chore.execute(chore, input)
  end

end
