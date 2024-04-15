defmodule Shifts.Shift do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chore, ShiftResult, Worker}

  defstruct operations: [], workers: %{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    operations: list({operation_name(), operation()}),
    workers: %{optional(worker_name()) => Worker.t()},
  }

  @type operation() ::
    {:task, Chore.t() | chore_fun()} |
    {:each, list(t())} |
    {:each_async, list(t())} |
    {:run, run_fun()}

  @type operation_name() :: atom()
  @type worker_name() :: atom()

  @type chore_fun() :: (ShiftResult.outputs() -> Chore.t())
  @type run_fun() :: (ShiftResult.outputs() -> term())


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
      Module.register_attribute(__MODULE__, :workers, accumulate: true)
      alias Shifts.Shift
      import Shift
      @behaviour Shift
      @before_compile Shift

      def init(opts \\ []), do: init(shift(), opts)

      @impl Shift
      def init(%Shift{} = shift, _opts), do: shift

      defoverridable init: 2
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defp shift() do
        Enum.reduce(@workers, %Shifts.Shift{}, fn {name, worker}, shift ->
          update_in(shift.workers, & Map.put(&1, name, worker))
        end)
      end
    end
  end

  @doc """
  TODO
  """
  @spec worker(worker_name(), keyword()) :: Macro.t()
  defmacro worker(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      if name in Keyword.keys(@workers),
        do: raise "worker names must be unique: `#{inspect name}` already used"
      worker = Worker.new(opts)
      Module.put_attribute(__MODULE__, :workers, {name, worker})
    end
  end


  ### Functions

  @doc """
  TODO
  """
  @spec each_async(t(), operation_name(), Enumerable.t(), (t(), term() -> t())) :: t()
  def each_async(%__MODULE__{} = shift, name, enum, callback)
    when is_function(callback, 2)
  do
    children = Enum.reduce(enum, [], fn value, shifts ->
      child_shift = put_in(shift.operations, [])
      [callback.(child_shift, value) | shifts]
    end)

    add_operation(shift, name, {:each_async, children})
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
  @spec run(t(), operation_name(), run_fun()) :: t()
  def run(%__MODULE__{} = shift, name, run_fun) when is_function(run_fun, 1),
    do: add_operation(shift, name, {:run, run_fun})

  @doc """
  TODO
  """
  @spec task(t(), operation_name(), Chore.t() | keyword() | chore_fun()) :: t()
  def task(%__MODULE__{} = shift, name, %Chore{} = chore),
    do: add_operation(shift, name, {:task, chore})

  def task(%__MODULE__{} = shift, name, chore_fun) when is_function(chore_fun, 1),
    do: add_operation(shift, name, {:task, chore_fun})

  def task(%__MODULE__{} = shift, name, opts) when is_list(opts),
    do: task(shift, name, Chore.new(opts))


  ### Internal

  @spec add_operation(t(), operation_name(), operation()) :: t()
  defp add_operation(%__MODULE__{operations: operations} = shift, name, op) do
    if name in Keyword.keys(operations),
      do: raise "operation names must be unique: `#{inspect name}` already used"

    put_in(shift.operations, [{name, op} | operations])
  end

end
