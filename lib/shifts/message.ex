defmodule Shifts.Message do
  @enforce_keys [:role, :content]
  defstruct role: nil, content: nil

  @type t() :: %__MODULE__{
    role: role(),
    content: String.t(),
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
      required: true,
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
    NimbleOptions.validate!(opts, @schema)
    struct!(__MODULE__, opts)
  end
end
