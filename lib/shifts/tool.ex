defmodule Shifts.Tool do
  @moduledoc """
  TODO
  """
  @enforce_keys [:name, :description, :function]
  defstruct name: nil, description: nil, params: [], function: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    name: String.t(),
    description: String.t(),
    params: list(param()),
    function: (args() -> String.t()),
  }

  @type param() :: {atom(), param_type(), String.t()}
  @type param_type() :: :string | :integer | :float
  @type args() :: %{optional(String.t()) => arg_type()}
  @typep arg_type() :: String.t() | integer() | float()

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
      type: {:fun, 1},
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
  def invoke(%__MODULE__{params: params} = tool, args) when is_map(args) do
    param_names = Enum.map(params, & elem(&1, 0))
    try do
      args = Enum.reduce(args, %{}, & normalize_arg(&2, &1, param_names))
      apply(tool.function, [args])
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
  @spec validate_tool(t() | module()) :: {:ok, t()} | {:error, String.t()}
  def validate_tool(%__MODULE__{} = tool), do: {:ok, tool}
  def validate_tool(tool_mod) do
    if is_atom(tool_mod) and :erlang.function_exported(tool_mod, :to_tool, 0),
      do: {:ok, tool_mod.to_tool()},
      else: {:error, "must be a module that implements the Tool behaviour"}
  end


  ### Behaviour

  @doc """
  Invoked when the tool is called, and must return a `String.t()` value.

  Receives a map of arguments.
  """
  @callback call(args :: map()) :: String.t()


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
        function: &__MODULE__.call/1,
      ])

      def to_tool(), do: @tool
    end
  end

end
