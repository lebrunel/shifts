defmodule Shifts.Job do
  alias Shifts.{ChatResult, Shift}
  alias Shifts.Job.Cell

  @behaviour Access
  defdelegate fetch(struct, key), to: Map
  defdelegate get_and_update(struct, key, function), to: Map
  defdelegate pop(struct, key), to: Map

  @enforce_keys [:name, :shift]
  defstruct name: nil, shift: nil, input: nil, tape: []

  @type t() :: %__MODULE__{
    name: name(),
    shift: Shift.t(),
    input: any(),
    tape: list(Cell.t()),
  }

  @type name() :: atom()
  @type chore_name() :: term()

  @spec open_cell(t()) :: t()
  def open_cell(%__MODULE__{} = job) do
    update_in(job.tape, & List.insert_at(&1, -1, %Cell{}))
  end

  @spec close_cell(t(), Cell.close_reason()) :: t()
  def close_cell(%__MODULE__{} = job, reason) do
    update_in(job.tape, fn tape ->
      List.update_at(tape, -1, & Map.put(&1, :close, reason))
    end)
  end

  @spec push_to_cell(t(), Cell.instruction()) :: t()
  def push_to_cell(%__MODULE__{} = job, instruction) do
    update_in(job.tape, fn tape ->
      List.update_at(tape, -1, & Cell.push(&1, instruction))
    end)
  end

  @spec get_state(t()) :: list({chore_name(), ChatResult.t()})
  def get_state(%__MODULE__{tape: tape}) do
    Enum.flat_map(tape, fn cell ->
      Enum.map(cell.instructions, fn {_, name, chat} -> {name, ChatResult.new(chat)} end)
    end)
  end

end
