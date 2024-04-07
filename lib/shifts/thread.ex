defmodule Shifts.Thread do
  @moduledoc """
  TODO
  """
  defstruct messages: []

  @type t() :: %__MODULE__{
    messages: list()
  }
end
