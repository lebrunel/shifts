defmodule Shifts.Shift do
  @moduledoc """
  TODO
  """
  alias Shifts.Session

  defstruct foo: :bar

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    foo: :bar
  }

  @doc """
  TODO
  """
  @callback call(session :: term(), input :: term()) :: term()

  defmacro __using__(_) do
    quote do
      import Shifts.Session
      @behaviour Shifts.Shift
    end
  end

  def start_session(%__MODULE__{} = shift) do
    %Session{shift: shift}
  end

end
