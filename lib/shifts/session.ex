defmodule Shifts.Session do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chore, Shift}

  @enforce_keys [:shift]
  defstruct shift: nil,
            scope: [],
            names: MapSet.new(),
            instructions: [],
            results: %{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    shift: Shift.t(),
    scope: list(name()),
    names: MapSet.t(atom()),
    instructions: list(instruction()),
    results: map(),
  }

  @type name() :: term()

  @type instruction() ::
    {:chore, name(), String.t() | (results() -> String.t()), Chore.t()},
    {:parallel, name(), list(instruction())}


  @type results() :: %{
    optional(name()) => String.t()
  }

  @doc """
  TODO
  """
  @spec instruct(
    t(),
    name(),
    String.t() | (results() -> String.t()),
    Chore.t() | keyword()
  ) :: t()
  def instruct(session, name, input, opts \\ [])

  def instruct(%__MODULE__{scope: []} = session, name, input, %Chore{} = chore)
    when is_binary(input) or is_function(input, 1)
  do
    assert_unique_name!(session, name)

    session
    |> Map.update!(:instructions, & [{:chore, name, input, chore} | &1])
    |> Map.update!(:names, & MapSet.put(&1, name))
  end

  def instruct(
    %__MODULE__{
      scope: [_ | _],
      instructions: [{:parallel, scoped, batch} | instructions]
    } = session,
    name,
    input,
    %Chore{} = chore
  ) when is_binary(input) or is_function(input, 1) do
    assert_in_scope!(session, scoped)
    assert_unique_name!(session, name)

    instruction = {:chore, name, input, chore}
    parallel = {:parallel, scoped, [instruction | batch]}

    session
    |> Map.put(:instructions, [parallel | instructions])
    |> Map.update!(:names, & MapSet.put(&1, name))
  end

  def instruct(%__MODULE__{} = session, name, input, opts) when is_list(opts) do
    instruct(session, name, input, Chore.new(opts))
  end

  @doc """
  TODO
  """
  @spec parallel(t(), name(), (t() -> t())) :: t()
  def parallel(%__MODULE__{scope: scope} = session, name, callback) do
    assert_unique_name!(session, name)

    session
    |> Map.update!(:names, & MapSet.put(&1, name))
    |> Map.put(:scope, [name | scope])
    |> callback.()
    |> Map.put(:scope, scope)
  end

  # TODO
  @spec assert_in_scope!(t(), name()) :: :ok | no_return()
  def assert_in_scope!(%__MODULE__{scope: [scoped | _]}, name)
    when scoped == name,
    do: :ok

  def assert_in_scope!(%__MODULE__{}, name),
    do: raise "parallel instruction name not in scope: #{name}"


  # TODO
  @spec assert_unique_name!(t(), name()) :: :ok | no_return()
  defp assert_unique_name!(%__MODULE__{names: names}, name) do
    if MapSet.member?(names, name),
      do: raise "instruction name must be unique: #{name}"
    :ok
  end

end
