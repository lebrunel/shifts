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
    {:chore, name(), String.t() | (results() -> String.t()), Chore.t()} |
    {:parallel, name(), list(list(instruction()))}


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

  def instruct(%__MODULE__{} = session, name, input, %Chore{} = chore)
    when is_binary(input) or is_function(input, 1)
  do
    assert_unique_name!(session, name)

    session
    |> add_instruction({:chore, name, input, chore})
    |> Map.update!(:names, & MapSet.put(&1, name))
  end

  def instruct(%__MODULE__{} = session, name, input, opts) when is_list(opts) do
    instruct(session, name, input, Chore.new(opts))
  end

  @doc """
  TODO
  """
  @spec parallel(t(), name(), Enum.t(), (t(), term() -> t())) :: t()
  def parallel(%__MODULE__{} = session, name, enum, callback)
    when is_function(callback, 2)
  do
    assert_unique_name!(session, name)

    session =
      session
      |> add_instruction({:parallel, name, []})
      |> Map.update!(:names, & MapSet.put(&1, name))
      |> Map.update!(:scope, & [name | &1])

    enum
    |> Enum.reduce(session, fn value, session ->
      session
      |> add_set()
      |> callback.(value)
    end)
    |> Map.update!(:scope, fn [_ | scope] -> scope end)
  end


  # TODO
  @spec add_instruction(t(), instruction()) :: t()
  defp add_instruction(%__MODULE__{} = session, instruction) do
    instructions =
      session.scope
      |> Enum.reverse()
      |> walk_instructions(session.instructions, instruction)

    Map.put(session, :instructions, instructions)
  end

  @spec walk_instructions(list(name()), list(instruction()), instruction()) :: list(instruction())
  def walk_instructions([], instructions, instruction) do
    [instruction | instructions]
  end

  def walk_instructions(
    [scope_name | scope],
    [{:parallel, name, [tip | set]} | instructions],
    instruction
  ) do
    if scope_name != name, do: raise "scope mis-match"
    tip = walk_instructions(scope, tip, instruction)
    [{:parallel, name, [tip | set]} | instructions]
  end

  @spec add_set(t()) :: t()
  defp add_set(%__MODULE__{} = session) do
    instructions =
      session.scope
      |> Enum.reverse()
      |> walk_sets(session.instructions)

    Map.put(session, :instructions, instructions)
  end

  @spec walk_sets(list(name()), list(instruction())) :: list(instruction())
  def walk_sets(
    [scope_name],
    [{:parallel, name, sets} | instructions]
  ) do
    if scope_name != name, do: raise "scope mis-match"
    [{:parallel, name, [[] | sets]} | instructions]
  end

  def walk_sets(
    [scope_name | scope],
    [{:parallel, name, [tip | set]} | instructions]
  ) do
    if scope_name != name, do: raise "scope mis-match"
    tip = walk_sets(scope, tip)
    [{:parallel, name, [tip | set]} | instructions]
  end


  # TODO
  @spec assert_unique_name!(t(), name()) :: :ok | no_return()
  defp assert_unique_name!(%__MODULE__{names: names}, name) do
    if MapSet.member?(names, name),
      do: raise "instruction name must be unique: #{inspect name}"
    :ok
  end

end
