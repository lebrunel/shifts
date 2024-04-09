defmodule Shifts.ChatResult do
  @moduledoc """
  TODO
  """
  alias Shifts.Chat

  @enforce_keys [:input, :output, :chat]
  defstruct input: nil, output: nil, chat: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    input: String.t(),
    output: String.t(),
    chat: Chat.t(),
  }

end
