defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chat, ChatResult, Shift, Templates, Tool}

  @default_llm Shifts.Config.get(:default_llm)

  @enforce_keys [:task, :output]
  defstruct task: nil, output: nil, tools: [], worker: @default_llm

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t(),
    tools: list(Tool.t()),
    worker: term() | {module(), keyword()}, # todo
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
    worker: [
      type: :any,
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

  @doc """
  TODO
  """
  @spec execute(t(), String.t() | nil) :: ChatResult.t()
  def execute(%__MODULE__{} = chore, input \\ nil) do
    {llm, tools} = case chore.worker do
      {mod, args} -> {{mod, args}, chore.tools}
    end

    Chat.init(llm)
    |> Chat.put_system(to_prompt(chore, :system))
    |> Chat.put_tools(tools)
    |> Chat.add_message(:user, to_prompt(chore, input))
    |> Chat.generate_next_message()
    |> Chat.handle_tool_use(%Shift{})
    |> Chat.finalize()
  end

  @doc """
  TODO
  """
  @spec to_prompt(t(), String.t() | :system | nil) :: String.t() | nil
  def to_prompt(chore, input \\ nil)

  def to_prompt(%__MODULE__{}, :system), do: nil

  def to_prompt(%__MODULE__{} = chore, input) do
    params = %{
      "task" => String.trim(chore.task),
      "output" => String.trim(chore.output),
      "input" => input,
    }

    Templates.get(:chore_prompt)
    |> ExMustache.render(params)
    |> IO.iodata_to_binary()
    |> String.trim()
  end


  ### Internal

  # TODO
  @spec use_tools(list(Tool.t() | module())) :: list(Tool.t())
  defp use_tools(tools) when is_list(tools) do
    Enum.map(tools, fn
      %Tool{} = tool -> tool
      tool_mod -> apply(tool_mod, :to_struct, [])
    end)
  end

end
