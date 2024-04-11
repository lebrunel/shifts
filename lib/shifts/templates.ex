defmodule Shifts.Templates.Macros do
  @moduledoc false
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

  {{#input}}Input: {{input}}

  {{/input}}
  This is the expected output for your final answer: {{output}}
  """

  template :worker_prompt, """
  Your role is {{role}}.
  {{#story}}{{story}}
  {{/story}}

  Your personal goal: {{goal}}
  """

  @doc """
  TODO
  """
  @spec get(atom()) :: ExMustache.t()
  def get(name), do: Keyword.fetch!(@templates, name)

end
