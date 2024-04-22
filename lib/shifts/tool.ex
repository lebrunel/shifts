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
  @spec invoke(t(), args()) :: String.t()
  def invoke(%__MODULE__{} = tool, args) when is_map(args),
    do: invoke(tool, %Shift{}, args)

  def invoke(%__MODULE__{params: params} = tool, %Shift{} = shift, args) when is_map(args) do
    param_names = Enum.map(params, & elem(&1, 0))
    try do
      args = Enum.reduce(args, %{}, & normalize_arg(&2, &1, param_names))
      apply(tool.function, [shift, args])
    rescue
      e ->
        "#{inspect e.__struct__}: #{Exception.message(e)}"
    end
  end

  # TODO
  defp normalize_arg(args, {key, val}, param_names) when is_atom(key) do
    if key in param_names do
      Map.put(args, key, val)
    else
      # todo - log this as the llm has given a non-existing arg name
      args
    end
  end

  defp normalize_arg(args, {key, val}, param_names) do
    try do
      normalize_arg(args, {String.to_existing_atom(key), val}, param_names)
    rescue
      ArgumentError ->
        # todo - log this as the llm has given a non-existing arg name
        args
    end
  end

  @doc """
  TODO
  """
  @spec use_tools(list(t() | module())) :: list(t())
  def use_tools(tools) when is_list(tools) do
    Enum.map(tools, fn
      %__MODULE__{} = tool -> tool
      mod when is_atom(mod) -> mod.to_tool()
    end)
  end

  @doc """
  TODO
  """
  @spec validate_mod(term()) :: {:ok, term()} | {:error, String.t()}
  def validate_mod(tool_mod) do
    if is_atom(tool_mod) and :erlang.function_exported(tool_mod, :to_tool, 0),
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
        inspect(__MODULE__)
        |> String.split(".")
        |> List.last()

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

      def to_tool(), do: @tool
    end
  end

end
