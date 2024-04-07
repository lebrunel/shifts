defmodule Shifts.Tool do
  @moduledoc """
  TODO
  """
  alias Shifts.{Job, Thread}

  @enforce_keys [:name, :description, :function]
  defstruct name: nil, description: nil, params: [], function: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    name: String.t(),
    description: String.t(),
    params: list(param()),
    function: (Job.t(), args() -> String.t() | Thread.t()),
  }

  @type param() :: {atom(), param_type(), String.t()}
  @type param_type() :: :string | :integer | :float
  @type args() :: %{optional(String.t()) => arg_type()}
  @typep arg_type() :: String.t() | integer() | float()


  @schema NimbleOptions.new!([
    name: [
      type: :atom,
      required: true,
      doc: "todo"
    ],
    description: [
      type: :string,
      required: true,
      doc: "todo"
    ],
    params: [
      type: {:list, {:tuple, [
        :atom,
        {:in, [:string, :integer, :float]},
        :string
      ]}},
      doc: "todo"
    ],
    function: [
      type: {:fun, 2},
      required: true,
      doc: "todo"
    ]
  ])

  @doc false
  @spec schema() :: NimbleOptions.t()
  def schema(), do: @schema

  @doc """
  Creates a new `t:Shifts.Tool.t/0` struct from the given options.
  """
  def new(opts \\ []) do
    NimbleOptions.validate!(opts, @schema)
    struct!(__MODULE__, opts)
  end

  @doc """
  TODO
  """
  @spec validate_mod(term()) :: {:ok, term()} | {:error, String.t()}
  def validate_mod(tool_mod) do
    if is_atom(tool_mod) and :erlang.function_exported(tool_mod, :to_struct, 0),
      do: {:ok, tool_mod},
      else: {:error, "must be a module that implements the Tool behaviour"}
  end


  ### Behaviour

  @doc """
  Invoked when the tool is called, and must return a `String.t()` value.

  Receives the context `t:Shifts.Shift.t/0` and a map of arguments.
  """
  @callback call(job :: Job.t(), args :: map()) :: String.t() | Thread.t()


  ### Macros

  @doc """
  Sets the tool description.
  """
  @spec description(String.t()) :: Macro.t()
  defmacro description(value) when is_binary(value) do
    quote do
      Module.put_attribute(__MODULE__, :description, unquote(value))
    end
  end

  @doc """
  Sets a tool parameter.
  """
  @spec param(atom(), param_type(), String.t()) :: Macro.t()
  defmacro param(name, type, description)
    when is_atom(name)
    and type in [:string, :integer, :float]
    and is_binary(description)
  do
    quote do
      Module.put_attribute(__MODULE__, :params, {
        unquote(name),
        unquote(type),
        unquote(description),
      })
    end
  end

  # using callback
  # imports the Tool macros
  # sets the Tool behaviour
  # and triggers before_compile callback
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :description, accumulate: false)
      Module.register_attribute(__MODULE__, :params, accumulate: true)
      import Shifts.Tool, only: [description: 1, param: 3]
      @behaviour Shifts.Tool
      @before_compile Shifts.Tool
    end
  end

  # before compile callback
  # builds the tool struct at compile time
  defmacro __before_compile__(_env) do
    quote do
      @tool Shifts.Tool.new([
        name: __MODULE__,
        description: @description,
        params: @params,
        function: &__MODULE__.call/2,
      ])

      def to_struct(), do: @tool
    end
  end

end
