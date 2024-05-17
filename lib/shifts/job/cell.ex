defmodule Shifts.Job.Cell do
  alias Shifts.Chat

  defstruct instructions: [], close: nil

  @type t() :: %__MODULE__{
    instructions: list(instruction()),
    close: nil | close_reason(),
  }

  @type name() :: term()

  @type instruction() :: {:exec, term(), Chat.t()}

  @type close_reason() :: :halt | {:next, name()}

  def push(%__MODULE__{} = cell, instruction) do
    update_in(cell.instructions, & List.insert_at(&1, -1, instruction))
  end

end
