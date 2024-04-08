defmodule Shifts.Message do
  @moduledoc """
  TODO
  """
  require Record
  alias Shifts.Tool

  @enforce_keys [:role]
  defstruct role: nil, content: nil, records: []

  @type t() :: %__MODULE__{
    role: role(),
    content: String.t(),
    records: list(Tool.tool_record()),
  }

  @type role() :: :user | :assistant

  @schema NimbleOptions.new!([
    role: [
      type: {:in, [:user, :assistant]},
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
  @spec put_record(t(), Tool.tool_record()) :: t()
  def put_record(%__MODULE__{} = msg, tool_record) do
    update_in(msg.records, & List.insert_at(&1, -1, tool_record))
  end
end
