defmodule Shifts.Shift.Runner do
  alias Shifts.{ChatResult, Chore, Shift, ShiftResult, Worker}

  @doc """
  TODO
  """
  @spec init(module(), term(), keyword()) :: Shift.t()
  def init(shift_mod, input, opts \\ []) do
    opts
    |> shift_mod.init()
    |> shift_mod.work(input)
  end

  @doc """
  TODO
  """
  @spec run(Shift.t()) :: ShiftResult.t()
  def run(%Shift{operations: operations} = shift) do
    results =
      operations
      |> Enum.reverse()
      |> Enum.reduce(%ShiftResult{shift: shift}, fn {name, operation}, results ->
        result = process_op(operation, results)
        update_in(results.chats, & [{name, result} | &1])
      end)

    with {_name, %ChatResult{output: output}} <- hd(results.chats) do
      results
      |> Map.put(:output, output)
      |> Map.update!(:chats, &Enum.reverse/1)
    end
  end


  ### Internal

  # TODO
  @spec process_op(Shift.operation(), ShiftResult.t()) :: term()
  defp process_op({:task, chore_fun}, result) when is_function(chore_fun, 1) do
    case chore_fun.(ShiftResult.to_outputs(result)) do
      %Chore{} = chore ->
        process_op({:task, chore}, result)
      res ->
        # todo - better error
        raise "anonymous task function must return a %Chore{} struct. Returns:\n  #{inspect res}"
    end
  end

  defp process_op({:task, %Chore{worker: worker_name} = chore}, %{shift: shift} = result)
    when is_atom(worker_name) and not is_nil(worker_name)
  do
    case Map.get(shift.workers, worker_name) do
      %Worker{} = worker ->
        process_op({:task, Map.put(chore, :worker, worker)}, result)
      _ ->
        # todo - better error
        raise "worker not found: #{inspect worker_name}"

    end
  end

  defp process_op({:task, %Chore{} = chore}, _result),
    do: Chore.execute(chore)

  defp process_op({:each, shifts}, _result),
    do: Enum.map(shifts, &run/1)

  defp process_op({:each_async, shifts}, _result) do
    shifts
    |> Enum.map(fn shift -> Task.async(fn -> run(shift) end) end)
    |> Task.await_many(:infinity)
  end

  defp process_op({:run, run_fun}, result) when is_function(run_fun, 1) do
    case run_fun.(ShiftResult.to_outputs(result)) do
      output when is_binary(output) ->
        output
      res ->
        # todo - better error
        raise "anonymous run function must return a String. Returns:\n  #{inspect res}"
    end
  end

end
