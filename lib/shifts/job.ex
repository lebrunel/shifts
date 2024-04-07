defmodule Shifts.Job do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chore, Shift}

  defstruct shift: nil,
            names: MapSet.new(),
            operations: [],
            results: %{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    shift: Shift.t(),
    names: MapSet.t(operation_name()),
    operations: list({operation_name(), operation()}),
    results: map(),
  }

  @type operation() ::
    {Chore.t(), chore_input()} |
    {:each, list(t())}

  @type operation_name() :: atom()

  @type chore_input() :: String.t() | operation_name() | (map() -> String.t())

  defguard is_chore_input(input)
    when is_binary(input)
    or is_atom(input)
    or is_function(input, 1)


  ### Behaviour

  @doc """
  TODO
  """
  @callback work(job :: t(), input :: term()) :: t()

  defmacro __using__(_) do
    quote do
      alias Shifts.Job
      import Job
      @behaviour Job
    end
  end


  ### Functions

  @doc """
  TODO
  """
  @spec chore(t(), operation_name(), chore_input(), Chore.t() | keyword()) :: t()
  def chore(job, name, input, opts \\ [])

  def chore(%__MODULE__{} = job, name, input, %Chore{} = chore)
    when is_chore_input(input)
  do
    job
    |> register_name(name)
    |> add_operation(name, {chore, input})
  end

  def chore(%__MODULE__{} = job, name, input, opts) when is_list(opts),
    do: chore(job, name, input, Chore.new(opts))


  @doc """
  TODO
  """
  @spec each(t(), operation_name(), Enumerable.t(), (t(), term() -> t())) :: t()
  def each(%__MODULE__{} = job, name, enum, callback)
    when is_function(callback, 2)
  do
    children = Enum.reduce(enum, [], fn value, jobs ->
      child_job =
        %__MODULE__{shift: job.shift}
        |> callback.(value)
      [child_job | jobs]
    end)

    job
    |> register_name(name)
    |> add_operation(name, {:each, children})
  end


  ### Internal

  @spec add_operation(t(), operation_name(), operation()) :: t()
  defp add_operation(%__MODULE__{operations: operations} = job, name, op),
    do: put_in(job.operations, [{name, op} | operations])

  @spec register_name(t(), operation_name()) :: t() | no_return()
  defp register_name(%__MODULE__{} = job, name) do
    if MapSet.member?(job.names, name),
      do: raise "operation names must be unique: `#{inspect name}` already used"
    update_in(job.names, & MapSet.put(&1, name))
  end

end
