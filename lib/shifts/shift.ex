defmodule Shifts.Shift do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chore, Job}

  @enforce_keys [:mod]
  defstruct mod: nil, workers: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    mod: module(),
    workers: list(),
  }

  @typedoc "TODO"
  @type on_next() :: {:cont, Job.phase_name(), Job.t()} | {:halt, Job.t()}

  @doc """
  TODO
  """
  @callback start_job(name :: Job.name(), job:: Job.t()) :: on_next()

  @callback handle_cell(name :: Job.phase_name(), job :: Job.t()) :: on_next()

  @callback handle_chore(name :: Job.chore_name(), job :: Job.t()) ::
    {:ok, String.t() | keyword() | Chore.t()} |
    {:error, term()}

  @doc """
  TODO
  """
  @spec worker(atom(), keyword()) :: Macro.t()
  defmacro worker(name, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :workers, {unquote(name), unquote(opts)})
    end
  end

  defmacro __using__(_) do
    quote do
      import Shifts.Shift, only: [worker: 2]
      import Shifts.Job.Helpers

      Module.register_attribute(__MODULE__, :workers, accumulate: true)
      @behaviour Shifts.Shift
      @before_compile Shifts.Shift

      @spec start_job(Job.name()) :: {:ok, Job.t()} | {:error, term()}
      def start_job(name) when is_atom(name) do
        job =
          Job
          |> struct!(name: name, shift: shift())
          |> Job.open_cell()

        loop(start_job(name, job))
      end

      def start_job(name, job), do: {:halt, job}
      def handle_cell(name, job), do: {:halt, job}
      def handle_chore(name, job), do: {:error, :todo}

      defoverridable start_job: 2, handle_cell: 2, handle_chore: 2

      # TODO
      defp loop({:next, name, job}) do
        job =
          job
          |> Job.close_cell({:next, name})
          |> Job.open_cell()

        loop(handle_cell(name, job))
      end

      defp loop({:halt, job}) do
        job = Job.close_cell(job, :halt)
        {:ok, job}
      end

      defp loop({:error, error}) do
        {:error, error}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @shift struct!(Shifts.Shift, [
        mod: __MODULE__,
        workers: @workers,
      ])

      @spec shift() :: Shifts.Shift.t()
      def shift(), do: @shift
    end
  end

end
