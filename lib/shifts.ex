defmodule Shifts do
  @moduledoc """
  Documentation for `Shifts`.
  """
  alias Shifts.{Chat, Chore, Shift}

  @spec process_job(module(), term()) :: Shift.t()
  def process_job(module, input) do
    unless function_exported?(module, :work, 2) do
      # todo - better exception
      raise "not a shift module"
    end

    shift = apply(module, :work, [%Shift{}, input])

    shift.operations
    |> Enum.reverse()
    |> Enum.reduce(shift, fn {name, operation}, shift ->
      chat = process_operation(operation, shift)
      update_in(shift.results, & Map.put(&1, name, Chat.finalize(chat)))
    end)
  end

  @spec process_operation(Shift.operation(), Shift.t()) :: Chat.t()
  def process_operation({%Chore{} = chore, input}, %Shift{} = shift)
    when is_function(input, 1)
  do
    results =
      shift.results
      |> Enum.map(fn {key, {val, _chat}} -> {key, val} end)
      |> Enum.into(%{})

    # todo - handle if the input function errors
    process_operation({chore, input.(results)}, shift)
  end

  def process_operation({%Chore{} = chore, input}, %Shift{} = _shift)
    when is_binary(input)
  do
    Chore.execute(chore, input)
  end

end
