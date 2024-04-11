defmodule Shifts.Worker do
  @moduledoc """
  TODO
  """
  alias Shifts.{LLM, Templates, Tool}

  @enforce_keys [:role, :goal, :llm]
  defstruct role: nil, goal: nil, story: nil, tools: [], llm: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    role: String.t(),
    goal: String.t(),
    story: String.t() | nil,
    tools: list(Tool.t()),
    llm: LLM.adapter(),
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
      |> Keyword.update!(:tools, &Tool.use_tools/1)
      |> Keyword.put_new(:llm, Shifts.Config.get(:default_llm))

    struct(__MODULE__, opts)
  end

  @doc """
  TODO
  """
  @spec to_prompt(t()) :: String.t() | nil
  def to_prompt(%__MODULE__{story: story} = worker) do
    params = %{
      "role" => String.trim(worker.role),
      "goal" => String.trim(worker.goal),
      "story" => if(is_nil(story), do: nil, else: String.trim(story)),
    }

    Templates.get(:worker_prompt)
    |> ExMustache.render(params)
    |> IO.iodata_to_binary()
    |> String.trim()
  end

end
