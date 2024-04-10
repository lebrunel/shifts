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
    chats: list({Shift.operation_name(), ChatResult.t()})
  }

  @type outputs() :: %{
    optional(Shift.operation_name()) => String.t()
  }

  @doc """
  TODO
  """
  @spec to_outputs(t()) :: outputs()
  def to_outputs(%__MODULE__{chats: chats}) do
    Enum.reduce(chats, %{}, fn {name, %ChatResult{output: output}}, res ->
      Map.put(res, name, output)
    end)
  end

end
