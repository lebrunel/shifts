defmodule Shifts.Chat do
  @moduledoc """
  TODO
  """
  require Logger
  require Shifts.Tool
  alias Shifts.{Message, Tool}

  @enforce_keys [:llm]
  defstruct llm: nil, system: nil, tools: [], messages: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    llm: {module(), keyword()},
    system: String.t() | nil,
    tools: list(Tool.t()),
    messages: list(Message.t() | t()),
  }

  @doc """
  TODO
  """
  @spec init({module(), keyword()}) :: t()
  def init({module, args} = llm) when is_atom(module) and is_list(args),
    do: struct!(__MODULE__, llm: llm)

  @doc """
  TODO
  """
  @spec put_system(t(), String.t() | nil) :: t()
  def put_system(%__MODULE__{} = chat, nil), do: chat
  def put_system(%__MODULE__{} = chat, prompt) when is_binary(prompt),
    do: put_in(chat.system, prompt)

  @spec put_tools(t(), list(Tool.t())) :: t()
  def put_tools(%__MODULE__{} = chat, tools),
    do: put_in(chat.tools, tools)

  @doc """
  TODO
  """
  @spec add_message(t(), Message.t()) :: t()
  def add_message(%__MODULE__{} = chat, %Message{} = message),
    do: update_in(chat.messages, & [message | &1])

  @doc """
  TODO
  """
  @spec add_message(t(), Message.role(), String.t()) :: t()
  def add_message(%__MODULE__{} = chat, role, content),
    do: add_message(chat, Message.new(role: role, content: content))

  @doc """
  TODO
  """
  @spec generate_next_message(t()) :: t()
  def generate_next_message(
    %__MODULE__{
      llm: {llm, _opts},
      messages: [%{role: :user} | _]
    } = chat
  ) do
    response = apply(llm, :generate_next_message, [chat])
    message = apply(llm, :get_message, [response])
    # todo - get and merge metrics
    #metrics = apply(llm, :get_metrics, [response])
    update_in(chat.messages, & [message | &1])
  end

  # TODO - better error here
  def generate_next_message(%__MODULE__{}), do: raise "cannot generate message"

  @doc """
  TODO
  """
  @spec handle_tool_use(t()) :: t()
  def handle_tool_use(
    %__MODULE__{
      tools: tools,
      messages: [%{role: :assistant, records: records} | _]
    } = chat
  ) when length(records) > 0 do
    message = Enum.reduce(records, Message.new(role: :user), fn {:tool_use, id, name, input}, msg ->
      # todo - handle if tool raises
      with %Tool{} = tool <- Enum.find(tools, & &1.name == name) do
        output = apply(tool.function, [nil, input])
        # todo - assert tool returns with string
        result = Tool.tool_result(id: id, name: name, output: output)
        Message.put_record(msg, result)
      else
        # Tool not found. Just ignore it and hope for the best
        nil ->
          Logger.error("Tool not found for tool_use: #{name}")
          msg
      end
    end)

    chat
    |> add_message(message)
    |> generate_next_message()
    |> handle_tool_use()
  end

  def handle_tool_use(%__MODULE__{} = chat), do: chat

end
