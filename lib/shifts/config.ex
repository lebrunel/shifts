defmodule Shifts.Config do
  @otp_app :shifts

  @defaults [
    default_llm: {Shifts.LLM.Anthropic, model: "claude-3-haiku-20240307"}
  ]

  @type t() :: keyword()

  @spec get_all() :: t()
  def get_all() do
    @otp_app
    |> Application.get_all_env()
    |> Keyword.merge(@defaults)
  end

  @spec get(atom(), term()) :: term()
  def get(key, default \\ nil) when is_atom(key),
    do: Keyword.get(get_all(), key, default)

end
