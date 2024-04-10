defmodule Shifts.Tool do
  @moduledoc """
  TODO
  """
  require Record
  alias Shifts.{Shift, Chat}

  @enforce_keys [:name, :description, :function]
  defstruct name: nil, description: nil, params: [], function: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    name: String.t(),
    description: String.t(),
    params: list(param()),
    function: (Shift.t(), args() -> String.t() | Chat.t()),
  }

  @type param() :: {atom(), param_type(), String.t()}
  @type param_type() :: :string | :integer | :float
  @type args() :: %{optional(String.t()) => arg_type()}
  @typep arg_type() :: String.t() | integer() | float()

  Record.defrecord(:tool_use, id: nil, name: nil, input: %{})
  Record.defrecord(:tool_result, id: nil, name: nil, output: nil)

  @type tool_record() :: tool_call() | tool_result()
  @type tool_call() :: record(:tool_use, id: String.t(), name: String.t(), input: args())
  @type tool_result() :: record(:tool_result, id: String.t(), name: String.t(), output: String.t())


  @schema NimbleOptions.new!([
    name: [
      type: :string,
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
  @callback call(shift :: Shift.t(), args :: map()) :: String.t() | Chat.t()


  ### Macros

  @doc """
  Sets the tool name.
  """
  @spec name(String.t()) :: Macro.t()
  defmacro name(value) when is_binary(value) do
    quote do
      Module.put_attribute(__MODULE__, :name, unquote(value))
    end
  end

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
      tool_name =
        inspect(__MODULE__) |> String.replace(".", "_")

      Module.put_attribute(__MODULE__, :name, tool_name)
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
        name: @name,
        description: @description,
        params: @params,
        function: &__MODULE__.call/2,
      ])

      def to_struct(), do: @tool
    end
  end

end
