defmodule Shifts.Shift do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chore, Worker}

  defstruct operations: [], workers: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    operations: list({operation_name(), operation()}),
    workers: list() # todo
  }

  @type operation() ::
    {Chore.t(), chore_input()} |
    {:async, list(t())} |
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
  @callback init(shift :: t(), opts :: keyword()) :: t()

  @doc """
  TODO
  """
  @callback work(shift :: t(), input :: term()) :: t()

  defmacro __using__(_) do
    quote do
      alias Shifts.Shift
      import Shift
      @behaviour Shift

      def init(opts \\ []), do: init(%Shift{}, opts)

      @impl Shift
      def init(%Shift{} = shift, _opts), do: shift

      defoverridable init: 2
    end
  end


  ### Functions

  @doc """
  TODO
  """
  @spec chore(t(), operation_name(), chore_input(), Chore.t() | keyword()) :: t()
  def chore(shift, name, input, opts \\ [])

  def chore(%__MODULE__{} = shift, name, input, %Chore{} = chore)
    when is_chore_input(input)
  do
    add_operation(shift, name, {chore, input})
  end

  def chore(%__MODULE__{} = shift, name, input, opts) when is_list(opts),
    do: chore(shift, name, input, Chore.new(opts))

  @doc """
  TODO
  """
  @spec async(t(), operation_name(), Enumerable.t(), (t(), term() -> t())) :: t()
  def async(%__MODULE__{} = shift, name, enum, callback)
    when is_function(callback, 2)
  do
    children = Enum.reduce(enum, [], fn value, shifts ->
      child_shift = put_in(shift.operations, [])
      [callback.(child_shift, value) | shifts]
    end)

    add_operation(shift, name, {:async, children})
  end

  @doc """
  TODO
  """
  @spec each(t(), operation_name(), Enumerable.t(), (t(), term() -> t())) :: t()
  def each(%__MODULE__{} = shift, name, enum, callback)
    when is_function(callback, 2)
  do
    children = Enum.reduce(enum, [], fn value, shifts ->
      child_shift = put_in(shift.operations, [])
      [callback.(child_shift, value) | shifts]
    end)

    add_operation(shift, name, {:each, children})
  end

  @doc """
  TODO
  """
  @spec worker(t(), Worker.t() | keyword()) :: t()
  def worker(%__MODULE__{} = shift, %Worker{} = worker),
    do: update_in(shift.workers, & [worker | &1])

  def worker(%__MODULE__{} = shift, opts) when is_list(opts),
    do: worker(shift, Worker.new(opts))


  ### Internal

  @spec add_operation(t(), operation_name(), operation()) :: t()
  defp add_operation(%__MODULE__{operations: operations} = shift, name, op) do
    if name in Keyword.keys(operations),
      do: raise "operation names must be unique: `#{inspect name}` already used"

    put_in(shift.operations, [{name, op} | operations])
  end

end
