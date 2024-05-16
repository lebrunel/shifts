defmodule Shifts.LLM do
  @moduledoc """
  TODO
  """
  alias Shifts.Chat

  @typedoc "TODO"
  @type adapter() :: {module(), keyword()}

  @typedoc "TODO"
  @type response() :: map()

  @doc """
  TODO
  """
  @callback generate_next_message(chat :: Chat.t()) :: response()

  @doc """
  TODO
  """
  @callback get_message(response()) :: Chat.message()

  @doc """
  TODO
  """
  @callback get_metrics(response()) :: term()

end
