defmodule Shifts.ChatResult do
  alias Shifts.{Chat, Message}

  @enforce_keys [:input, :output, :messages]
  defstruct input: nil, output: nil, messages: []

  @type t() :: %__MODULE__{
    input: String.t(),
    output: String.t(),
    messages: list(Message.t()),
  }

  def new(%Chat{status: :done, messages: messages}) do
    first = hd(messages)
    last = Enum.at(messages, -1)

    struct!(__MODULE__, [
      input: first.content,
      output: last.content,
      messages: messages,
    ])
  end

end
