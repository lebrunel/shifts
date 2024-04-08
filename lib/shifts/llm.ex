defmodule Shifts.LLM do
  @moduledoc """
  TODO
  """
  alias Shifts.Message

  @typedoc "TODO"
  @type response() :: map()

  @doc """
  TODO
  """
  @callback generate_next_message(opts :: keyword()) :: response()

  @doc """
  TODO
  """
  @callback get_message(response()) :: Message.t()

  @doc """
  TODO
  """
  @callback get_metrics(response()) :: term()



end
