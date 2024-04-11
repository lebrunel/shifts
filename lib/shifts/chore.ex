defmodule Shifts.Chore do
  @moduledoc """
  TODO
  """
  alias Shifts.{Chat, ChatResult, LLM, Shift, Templates, Tool, Worker}

  @enforce_keys [:task, :output, :llm]
  defstruct task: nil, output: nil, tools: [], worker: nil, llm: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    task: String.t(),
    output: String.t(),
    tools: list(Tool.t()),
    worker: Worker.t() | nil,
    llm: LLM.adapter(),
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
      type: {:struct, Worker},
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
  @spec execute(t(), String.t() | nil) :: ChatResult.t()
  def execute(%__MODULE__{} = chore, input \\ nil) do
    Chat.init(get_llm(chore))
    |> Chat.put_system(to_prompt(chore, :system))
    |> Chat.put_tools(get_tools(chore))
    |> Chat.add_message(:user, to_prompt(chore, input))
    |> Chat.generate_next_message()
    |> Chat.handle_tool_use(%Shift{}) # todo - needs to pass through actual shift
    |> Chat.finalize()
  end

  @doc """
  TODO
  """
  @spec to_prompt(t(), String.t() | :system | nil) :: String.t() | nil
  def to_prompt(chore, input \\ nil)

  def to_prompt(%__MODULE__{worker: %Worker{} = worker}, :system),
    do: Worker.to_prompt(worker)

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
  @spec get_llm(t()) :: LLM.adapter()
  defp get_llm(%__MODULE__{worker: %Worker{llm: llm}}), do: llm
  defp get_llm(%__MODULE__{llm: llm}), do: llm

  @spec get_tools(t()) :: list(Tool.t())
  defp get_tools(%__MODULE__{
    tools: tools,
    worker: %Worker{tools: worker_tools}
  }), do: worker_tools ++ tools
  defp get_tools(%__MODULE__{tools: tools}), do: tools

end
