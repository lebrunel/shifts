defmodule Shifts.Thread do
  @moduledoc """
  TODO
  """
  alias Shifts.{Message, Tool}

  @enforce_keys [:llm]
  defstruct llm: nil, system: nil, tools: [], messages: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    llm: {module(), keyword()},
    system: String.t() | nil,
    messages: list()
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
  def put_system(%__MODULE__{} = thread, nil), do: thread
  def put_system(%__MODULE__{} = thread, prompt) when is_binary(prompt),
    do: put_in(thread.system, prompt)

  @spec put_tools(t(), list(Tool.t())) :: t()
  def put_tools(%__MODULE__{} = thread, tools),
    do: put_in(thread.tools, tools)

  @doc """
  TODO
  """
  @spec add_message(t(), Message.t()) :: t()
  def add_message(%__MODULE__{} = thread, %Message{} = message),
    do: update_in(thread.messages, & [message | &1])

  @doc """
  TODO
  """
  @spec add_message(t(), Message.role(), String.t()) :: t()
  def add_message(%__MODULE__{} = thread, role, content),
    do: add_message(thread, Message.new(role: role, content: content))

  @spec generate_next_message(t()) :: t()
  def generate_next_message(%__MODULE__{messages: [%{role: role} | _]} = thread)
    when role in [:user]
  do
    # TODO
    thread
  end

  # TODO - better error here
  def generate_next_message(%__MODULE__{}), do: raise "cannot generate message"


end
