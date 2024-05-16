defmodule Shifts.Chore do

  @enforce_keys [:task]
  defstruct task: nil, output: nil, context: nil, tools: [], worker: nil, llm: nil

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

  @doc """
  TODO
  """
  @spec to_prompt(t()) :: String.t()
  def to_prompt(%__MODULE__{} = chore) do
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
