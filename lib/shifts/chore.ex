defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chat, LLM, Tool, Worker}

  @enforce_keys [:task]
  defstruct task: nil, output: nil, context: nil, tools: [], worker: nil, llm: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t() | nil,
    context: String.t() | nil,
    tools: list(),
    worker: Worker.t() | nil,
    llm: LLM.adapter() | nil,
  }

  @schema NimbleOptions.new!([
    task: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    output: [
      type: :string,
      doc: "todo"
    ],
    context: [
      type: :string,
      doc: "todo"
    ],
    worker: [
      type: {:struct, Worker},
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

    struct!(__MODULE__, opts)
  end

  @doc """
  TODO
  """
  @spec exec(t()) :: Chat.t()
  def exec(%__MODULE__{} = chore) do
    init_chat(chore)
    |> Chat.add_message(:user, get_prompt(chore))
    |> Chat.generate_next_message()
  end

  @doc """
  TODO
  """
  @spec init_chat(t()) :: Chat.t()
  def init_chat(%__MODULE__{worker: %Worker{} = worker} = chore) do
    opts = case {worker.llm, chore.llm} do
      {nil, nil} -> []
      {nil, llm} -> [llm: llm]
      {llm, _llm} -> [llm: llm]
    end

    opts
    |> Keyword.put(:system, Worker.get_prompt(worker))
    |> Keyword.put(:tools, worker.tools ++ chore.tools)
    |> Chat.new()
  end

  def init_chat(%__MODULE__{} = chore) do
    opts = case chore.llm do
      nil -> []
      llm -> [llm: llm]
    end

    opts
    |> Keyword.put(:tools, chore.tools)
    |> Chat.new()
  end

  @doc """
  TODO
  """
  @spec get_prompt(t()) :: String.t()
  def get_prompt(%__MODULE__{} = chore) do
    chunks = [
      chore.task,
      if(chore.context, do: "This is the context you're working with:\n#{chore.context}"),
      if(chore.output, do: "This is the expected output for your final answer: #{chore.output}"),
    ]

    chunks
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

end
