defmodule Shifts.Templates.Macros do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      import Shifts.Templates.Macros
    end
  end

  defmacro template(name, raw_template) do
    quote do
      temp = ExMustache.parse(unquote(raw_template))
      Module.put_attribute(__MODULE__, :templates, {unquote(name), temp})
    end
  end
end

defmodule Shifts.Templates do
  @moduledoc false
  use Shifts.Templates.Macros


  template :chore_prompt, """
  {{task}}

  {{#input}}This is the context you're working with:

  {{input}}{{/input}}

  This is the expected output for your final answer: {{output}}
  """

  @doc """
  TODO
  """
  @spec get(atom()) :: ExMustache.t()
  def get(name), do: Keyword.fetch!(@templates, name)

end
