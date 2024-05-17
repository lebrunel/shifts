defmodule Shifts.Chat do
  @moduledoc """
  TODO
  """
  alias Shifts.{Config, LLM, Message}

  @enforce_keys [:llm]
  defstruct status: :pending, llm: nil, system: nil, tools: [], messages: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    status: status(),
    llm: LLM.adapter(),
    system: String.t() | nil,
    tools: list(),
    messages: list(Message.t()),
  }

  @typedoc "TODO"
  @type status() :: :pending | :ready | :done

  @schema NimbleOptions.new!([
    system: [
      type: :string,
      doc: "todo"
    ],
    tools: [
      type: {:list, :any},
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
      |> Keyword.put_new(:llm, Config.get(:default_llm))

    struct!(__MODULE__, opts)
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
  @spec add_message(t(), Message.t()) :: t()
  def add_message(
    %__MODULE__{status: status} = chat,
    %Message{role: role} = message
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

  @spec add_message(t(), Message.role(), String.t()) :: t()
  def add_message(%__MODULE__{} = chat, role, content) do
    add_message(chat, Message.new(role: role, content: content))
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
