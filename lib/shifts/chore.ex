defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """
  alias Shifts.Tool

  @enforce_keys [:task, :output]
  defstruct task: nil, output: nil, tools: [], llm: {}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t(),
    tools: list(Tool.t()),
    llm: term(), # todo
  }

  @schema NimbleOptions.new!([
    task: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    output: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    tools: [
      type: {:list, {:or, [
        {:struct, Tool},
        {:custom, Tool, :validate_mod, []},
      ]}},
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
      |> Keyword.update!(:tools, &use_tools/1)

    struct(__MODULE__, opts)
  end

  @spec use_tools(list(Tool.t() | module())) :: list(Tool.t())
  def use_tools(tools) when is_list(tools) do
    Enum.map(tools, fn
      %Tool{} = tool -> tool
      tool_mod -> apply(tool_mod, :to_struct, [])
    end)
  end

end
