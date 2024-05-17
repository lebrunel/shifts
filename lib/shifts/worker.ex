defmodule Shifts.Worker do
  @moduledoc """
  TODO
  """
  alias Shifts.{LLM, Tool}

  @enforce_keys [:role, :goal, :llm]
  defstruct role: nil, goal: nil, story: nil, tools: [], llm: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    role: String.t(),
    goal: String.t(),
    story: String.t() | nil,
    tools: list(),
    llm: LLM.adapter() | nil,
  }

  @schema NimbleOptions.new!([
    role: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    goal: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    story: [
      type: :string,
      doc: "todo"
    ],
    tools: [
      type: {:list, {:custom, Tool, :validate_tool, []}},
      default: [],
      doc: "todo"
    ],
    llm: [
      type: :mod_arg,
      doc: "todo"
    ]
  ])

  @doc false
  @spec schema() :: NimbleOptions.t()
  def schema(), do: @schema

  @doc """
  TODO
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    opts =
      opts
      |> NimbleOptions.validate!(@schema)

    struct(__MODULE__, opts)
  end

  @doc """
  TODO
  """
  @spec get_prompt(t()) :: String.t() | nil
  def get_prompt(%__MODULE__{} = worker) do
    """
    Your role is #{worker.role}.
    #{if(worker.story, do: "#{worker.story}\n")}
    Your personal goal: #{worker.goal}
    """
  end

end
