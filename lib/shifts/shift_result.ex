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

end
