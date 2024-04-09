defmodule Shifts.Chat do
  @moduledoc """
  TODO
  """
  require Logger
  require Shifts.Tool
  alias Shifts.{Message, ChatResult, Shift, Tool}

  @enforce_keys [:llm]
  defstruct llm: nil, system: nil, tools: [], messages: [], final: false

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    llm: {module(), keyword()},
    system: String.t() | nil,
    tools: list(Tool.t()),
    messages: list(Message.t() | t()),
    final: boolean(),
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
  def put_system(%__MODULE__{final: false} = chat, prompt)
    when is_binary(prompt)
    or is_nil(prompt),
    do: put_in(chat.system, prompt)

  @spec put_tools(t(), list(Tool.t())) :: t()
  def put_tools(%__MODULE__{final: false} = chat, tools)
    when is_list(tools),
    do: put_in(chat.tools, tools)

  @doc """
  TODO
  """
  @spec add_message(t(), Message.t()) :: t()
  def add_message(%__MODULE__{final: false} = chat, %Message{} = message),
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
      messages: [%{role: :user} | _],
      final: false
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
  @spec handle_tool_use(t(), Shift.t()) :: t()
  def handle_tool_use(
    %__MODULE__{
      tools: tools,
      messages: [%{role: :assistant, records: records} | _],
      final: false
    } = chat,
    %Shift{} = shift
  ) when length(records) > 0 do
    message = Enum.reduce(records, Message.new(role: :user), fn {:tool_use, id, name, input}, msg ->
      # todo - handle if tool raises
      with %Tool{} = tool <- Enum.find(tools, & &1.name == name) do
        output = apply(tool.function, [shift, input])
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
    |> handle_tool_use(shift)
  end

  def handle_tool_use(%__MODULE__{} = chat, _shift), do: chat

  @doc """
  TODO
  """
  @spec finalize(t()) :: ChatResult.t()
  def finalize(%__MODULE__{} = chat) do
    output = hd(chat.messages) |> Map.get(:content)
    chat = invert(chat)
    input = hd(chat.messages) |> Map.get(:content)

    %ChatResult{input: input, output: output, chat: chat}
  end


  ### Internal

  defp invert(%__MODULE__{} = chat) do
    update_in(chat.messages, fn messages ->
      messages
      |> Enum.map(& if match?(%__MODULE__{}, &1), do: invert(&1), else: &1)
      |> Enum.reverse()
    end)
    |> Map.put(:final, true)
  end

end
