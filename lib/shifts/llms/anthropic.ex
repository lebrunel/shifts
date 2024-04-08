defmodule Shifts.LLMs.Anthropic do
  alias Shifts.{Config, Chat, Message, Tool}

  @behaviour Shifts.LLM

  @impl true
  def generate_next_message(%Chat{llm: {_llm, opts}} = chat) do
    opts =
      opts
      |> Keyword.put(:system, chat.system)
      |> Keyword.put(:tools, use_tools(chat.tools))
      |> Keyword.put(:messages, Enum.reverse(chat.messages) |> use_messages())
      |> remove_blank_opts([:system, :tools])

    with {:ok, response} <- Anthropix.chat(client(), opts) do
      response
    else
      {:error, error} -> raise error
    end
  end

  @impl true
  def get_message(%{"content" => [%{"type" => "text", "text" => content}]}) do
    Message.new(role: :assistant, content: content)
  end

  # TODO
  @impl true
  def get_metrics(_response) do
    %{}
  end

  defp client() do
    Config.get(__MODULE__, [])
    |> Keyword.fetch!(:api_key)
    |> Anthropix.init()
  end

  defp remove_blank_opts(opts, keys) do
    Enum.reduce(keys, opts, fn key, opts ->
      case Keyword.get(opts, key) do
        res when res in [nil, []] -> Keyword.delete(opts, key)
        _ -> opts
      end
    end)
  end

  defp use_messages(messages) do
    Enum.map(messages, fn %Message{role: role, content: content} ->
      %{role: to_string(role), content: content}
    end)
  end

  defp use_tools(tools) do
    Enum.map(tools, fn %Tool{} = tool ->
      %{
        name: to_string(tool.name),
        description: String.trim(tool.description),
        input_schema: %{
          type: "object",
          properties: Enum.reduce(tool.params, %{}, fn {name, type, description}, props ->
            Map.put(props, name, %{
              type: to_string(type),
              description: String.trim(description),
            })
          end)
        }
      }
    end)
  end

end
