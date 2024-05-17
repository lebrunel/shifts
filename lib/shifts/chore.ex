defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chat, LLM}

  @enforce_keys [:task]
  defstruct task: nil, output: nil, context: nil, tools: [], worker: nil, llm: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t() | nil,
    context: String.t() | nil,
    tools: list(),
    worker: nil,
    llm: nil,
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

  def exec(%__MODULE__{} = chore) do
    Chat.init(get_llm(chore))
    |> Chat.put_system(get_system_prompt(chore))
    |> Chat.put_tools(get_tools(chore))
    |> Chat.add_message(:user, get_prompt(chore))
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

  # TODO
  @spec get_llm(t()) :: LLM.adapter()
  #defp get_llm(%__MODULE__{worker: %Worker{llm: llm}}), do: llm
  defp get_llm(%__MODULE__{llm: llm}), do: llm

  # TODO
  @spec get_system_prompt(t()) :: String.t() | nil
  #defp get_system_prompt(%__MODULE__{worker: %Worker{} = worker}),
  #  do: Worker.get_prompt(worker)
  defp get_system_prompt(%__MODULE__{}), do: nil

  # TODO
  @spec get_tools(t()) :: list()
  #defp get_tools(%__MODULE__{
  #  tools: tools,
  #  worker: %Worker{tools: worker_tools}
  #}), do: worker_tools ++ tools
  defp get_tools(%__MODULE__{tools: tools}), do: tools

end
