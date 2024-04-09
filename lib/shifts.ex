defmodule Shifts do
  @moduledoc """
  Documentation for `Shifts`.
  """
  alias Shifts.{ChatResult, Chore, Shift, ShiftResult}

  @spec process_job(module(), term()) :: ShiftResult.t()
  def process_job(module, input) do
    unless function_exported?(module, :work, 2) do
      # todo - better exception
      raise "not a shift module"
    end

    shift = apply(module, :work, [%Shift{}, input])

    results = shift.operations
    |> Enum.reverse()
    |> Enum.reduce(%ShiftResult{shift: shift}, fn {name, operation}, results ->
      result = process_operation(operation, results)
      update_in(results.chats, & [{name, result} | &1])
    end)

    with {_name, %ChatResult{output: output}} <- hd(results.chats) do
      results
      |> Map.put(:output, output)
      |> Map.update!(:chats, &Enum.reverse/1)
    end
  end

  @spec process_operation(Shift.operation(), ShiftResult.t()) :: ChatResult.t()
  def process_operation(
    {%Chore{} = chore, input},
    %ShiftResult{chats: chats} = result
  ) when is_function(input, 1)
  do
    results_map =
      Enum.reduce(chats, %{}, fn {name, %ChatResult{output: output}}, res ->
        Map.put(res, name, output)
      end)

    # todo - handle if the input function errors
    process_operation({chore, input.(results_map)}, result)
  end

  def process_operation({%Chore{} = chore, input}, %ShiftResult{})
    when is_binary(input),
    do: Chore.execute(chore, input)

end
