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
  alias Shifts.{Shift.Runner, ShiftResult}

  @doc """
  TODO
  """
  @spec start_shift(module(), term(), keyword()) :: ShiftResult.t()
  def start_shift(shift_mod, input, opts \\ []) do
    shift_mod
    |> Runner.init(input, opts)
    |> Runner.run()
  end

end
