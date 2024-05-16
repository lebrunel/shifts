defmodule Shifts.Chat do
  @moduledoc """
  TODO
  """
  require Record
  alias Shifts.{Config, LLM}

  @enforce_keys [:llm]
  defstruct status: :pending, llm: nil, system: nil, tools: [], messages: []

  Record.defrecord(:user_message, :user, content: nil, records: [])
  Record.defrecord(:chatbot_message, :chatbot, content: nil, records: [])

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    status: status(),
    llm: LLM.adapter(),
    system: String.t() | nil,
    tools: list(),
    messages: list(message()),
  }

  @typedoc "TODO"
  @type message() ::
    record(:user_message, content: String.t(), records: list()) |
    record(:chatbot_message, content: String.t(), records: list())

  @type status() :: :pending | :ready | :done

  @doc """
  TODO
  """
  @spec init(LLM.adapter() | nil) :: t()
  def init(nil), do: Config.get(:default_llm) |> init()
  def init({module, args} = llm) when is_atom(module) and is_list(args),
    do: struct!(__MODULE__, llm: llm)

  @doc """
  TODO
  """
  @spec get_input(t()) :: String.t()
  def get_input(%__MODULE__{status: status, messages: messages}) when status != :pending do
    user_message(content: content) = Enum.at(messages, 0)
    content
  end

  @doc """
  TODO
  """
  @spec get_output(t()) :: String.t()
  def get_output(%__MODULE__{status: status, messages: messages}) when status == :done do
    chatbot_message(content: content) = Enum.at(messages, -1)
    content
  end

  @doc """
  TODO
  """
  @spec put_system(t(), String.t() | nil) :: t()
  def put_system(%__MODULE__{} = chat, prompt) when is_binary(prompt),
    do: put_in(chat.system, prompt)
  def put_system(%__MODULE__{} = chat, nil), do: put_in(chat.system, nil)

  @doc """
  TODO
  """
  @spec put_tools(t(), list()) :: t()
  def put_tools(%__MODULE__{} = chat, tools)
    when is_list(tools),
    do: put_in(chat.tools, tools)

  @doc """
  TODO
  """
  @spec add_message(t(), message()) :: t()
  def add_message(
    %__MODULE__{status: status} = chat,
    {role, _content, _records} = message
  )
    when (role == :user and status != :ready)
    or (role == :chatbot and status == :ready)
  do
    new_status = case role do
      :user -> :ready
      :chatbot -> :done
    end

    update_in(chat.messages, & List.insert_at(&1, -1, message))
    |> Map.put(:status, new_status)
  end

  @doc """
  TODO
  """
  @spec generate_next_message(t()) :: t()
  def generate_next_message(%__MODULE__{status: :ready, llm: {llm, _opts}} = chat) do
    response = apply(llm, :generate_next_message, [chat])
    message = apply(llm, :get_message, [response])
    # todo - get and merge metrics
    #metrics = apply(llm, :get_metrics, [response])
    add_message(chat, message)
  end

end
