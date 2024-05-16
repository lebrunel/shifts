defmodule Shifts.Message do
  @moduledoc """
  TODO
  """
  require Record
  #alias Shifts.Tool

  @enforce_keys [:role]
  defstruct role: nil, content: nil, records: []

  Record.defrecord(:tool_use, id: nil, name: nil, input: nil)
  Record.defrecord(:tool_result, id: nil, name: nil, output: nil)

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    role: role(),
    content: String.t(),
    records: list(tool_record()),
  }

  @typedoc "TODO"
  @type role() :: :user | :chatbot

  @typedoc "TODO"
  @type tool_record() :: tool_use() | tool_result()

  @typedoc "TODO"
  @type tool_use() :: record(:tool_use, id: String.t() | nil, name: String.t(), input: map())

  @typedoc "TODO"
  @type tool_result() :: record(:tool_result, id: String.t() | nil, name: String.t(), output: String.t())

  @schema NimbleOptions.new!([
    role: [
      type: {:in, [:user, :chatbot]},
      required: true,
      doc: "todo"
    ],
    content: [
      type: :string,
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
    NimbleOptions.validate!(opts, @schema)
    struct!(__MODULE__, opts)
  end

  @doc """
  TODO
  """
  @spec put_record(t(), tool_record()) :: t()
  def put_record(%__MODULE__{} = msg, tool_record) do
    update_in(msg.records, & List.insert_at(&1, -1, tool_record))
  end
end
