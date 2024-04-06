defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """

  @enforce_keys [:task, :output]
  defstruct task: nil, output: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t(),
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

end
