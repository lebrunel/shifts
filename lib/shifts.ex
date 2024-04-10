defmodule Shifts do
  @moduledoc """
  ![License](https://img.shields.io/github/license/lebrunel/shifts?color=informational)

  Shifts is a framework for composing autonomous **agent** workflows, using a
  mixture of LLM backends.

  - 🤖 **Automate your chores** - have AI agents handle the mundane so you can focus on the things you care about.
  - 💪🏻 **Agents with superpowers** - create tools, so your agents can interact with the Web or internal APIs and systems.
  - 🧩 **Flexible and adaptable** - easily compose and modify workflows to suit your specific needs.
  - 🤗 **Delightful simplicity** - pipe instructions together using just plain English and intuitive APIs.
  - 🎨 **Mix and match** - Plug into different LLMs even within the same workflow so you are always using the right tool for job.

  ### Current dev status

  | Version   | Stability                                                  | Status              |
  | --------- | -----------------------------------------------------------| ------------------- |
  | `0.0.x`   | For the brave and adventurous - expect breaking changes.   | **👈🏻 We are here!**  |
  | `0.x.0`   | Focus on better docs with less frequent breaking changes.  |                     |
  | `1.0.0` + | 🚀 Launched. Great docs, great dev experience, stable APIs. |                     |

  ### Currently supported LLMs

  - Anthropic / Claude 3 - **Recommended**
  - Ollama - Hermes Pro

  ## Installation

  The package can be installed by adding `shifts` to your list of dependencies
  in `mix.exs`.

  ```elixir
  def deps do
    [
      {:shifts, "~> #{Keyword.fetch!(Mix.Project.config(), :version)}"}
    ]
  end
  ```

  Documentation to follow...
  """
  alias Shifts.{ChatResult, Chore, Shift, ShiftResult}

  @doc """
  TODO
  """
  @spec process(module(), term()) :: ShiftResult.t()
  def process(module, input) do
    unless function_exported?(module, :work, 2) do
      # todo - better exception
      raise "not a shift module"
    end

    %Shift{}
    |> module.work(input)
    |> process_shift()
  end

  @doc """
  TODO
  """
  @spec process_shift(Shift.t()) :: ShiftResult.t()
  def process_shift(%Shift{operations: operations} = shift) do
    results =
      operations
      |> Enum.reverse()
      |> Enum.reduce(%ShiftResult{shift: shift}, fn {name, operation}, results ->
        result = process_operation(operation, results)
        update_in(results.chats, & [{name, result} | &1])
      end)

    with {_name, %ChatResult{output: output}} <- hd(results.chats) do
      results
      |> Map.put(:output, output)
      |> Map.update!(:chats, &Enum.reverse/1)
    end
  end

  # TODO
  # todo - handle each op
  @spec process_operation(Shift.operation(), ShiftResult.t()) :: ChatResult.t()
  defp process_operation(
    {%Chore{} = chore, input_fun},
    %ShiftResult{} = result
  ) when is_function(input_fun, 1)
  do
    # todo - handle if the input function errors
    input = input_fun.(ShiftResult.to_outputs(result))
    process_operation({chore, input}, result)
  end

  defp process_operation({%Chore{} = chore, input}, %ShiftResult{})
    when is_binary(input),
    do: Chore.execute(chore, input)

  defp process_operation({:async, shifts}, %ShiftResult{}) do
    shifts
    |> Enum.map(fn shift ->
      Task.async(fn -> process_shift(shift) end)
    end)
    |> Task.await_many(:infinity)
  end

  defp process_operation({:each, shifts}, %ShiftResult{}),
    do: Enum.map(shifts, &process_shift/1)

end
