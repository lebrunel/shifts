ExUnit.configure(exclude: [pending: true])
ExUnit.start()

defmodule TestTool do
  use Shifts.Tool

  description "test"

  def call(_job, _args), do: "test"
end
