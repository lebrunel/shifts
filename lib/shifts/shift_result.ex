defmodule Shifts.ShiftResult do
  @moduledoc """
  TODO
  """
  alias Shifts.{ChatResult, Shift}

  defstruct shift: nil, output: nil, chats: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    shift: Shift.t(),
    output: String.t(),
    chats: list({Shift.operation_name(), ChatResult.t() | String.t() | list(t())})
  }

  @type outputs() :: %{
    optional(Shift.operation_name()) => String.t()
  }

  @doc """
  TODO
  """
  @spec to_outputs(t()) :: outputs()
  def to_outputs(%__MODULE__{chats: chats}) do
    Enum.reduce(chats, %{}, &reduce_results/2)
  end


  ### Internal

  # TODO
  @spec reduce_results({Shift.operation_name(), term()}, map()) :: map()
  defp reduce_results({name, %{output: output}}, res),
    do: Map.put(res, name, output)

  defp reduce_results({name, shift_results}, res) when is_list(shift_results) do
    outputs = Enum.map(shift_results, fn %{output: output} -> output end)
    Map.put(res, name, outputs)
  end

  defp reduce_results({name, output}, res), do: Map.put(res, name, output)

end
