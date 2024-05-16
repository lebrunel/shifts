defmodule Shifts.LLM.Anthropic do
  @moduledoc """
  TODO
  """
  #require Shifts.Tool
  alias Shifts.{Config, Chat, Message}

  @behaviour Shifts.LLM

  @impl true
  def generate_next_message(%Chat{llm: {_llm, opts}} = chat) do
    opts =
      opts
      |> Keyword.put(:system, chat.system)
      #|> Keyword.put(:tools, tool_params(chat.tools))
      |> Keyword.put(:messages, message_params(chat.messages))
      |> remove_blank_opts([:system, :tools])

    with {:ok, response} <- Anthropix.chat(client(), opts) do
      response
    else
      {:error, error} -> raise error
    end
  end

  @impl true
  def get_message(%{"content" => content_blocks}) do
    Enum.reduce(content_blocks, Message.new(role: :chatbot), fn
      %{"type" => "text", "text" => content}, msg ->
        Map.put(msg, :content, content)

      %{"type" => "tool_use", "id" => id, "name" => name, "input" => input}, msg ->
        Message.put_record(msg, {:tool_use, id, name, input})

      # ignore any other block types
      _, msg -> msg
    end)
  end

  # TODO
  @impl true
  def get_metrics(_response) do
    %{}
  end

  ### Internal

  @spec client() :: Anthropix.client()
  defp client() do
    Config.get(__MODULE__, [])
    |> Keyword.fetch!(:api_key)
    |> Anthropix.init()
  end

  @spec remove_blank_opts(keyword(), list(atom())) :: keyword()
  defp remove_blank_opts(opts, keys) do
    Enum.reduce(keys, opts, fn key, opts ->
      case Keyword.get(opts, key) do
        res when res in [nil, []] -> Keyword.delete(opts, key)
        _ -> opts
      end
    end)
  end

  @spec message_params(list(Message.t())) :: list(Anthropix.message())
  defp message_params(messages) do
    messages
    |> Enum.reverse()
    |> Enum.map(fn
      %Message{role: role, content: content, records: []} ->
        %{role: to_string(role), content: content}

      %Message{role: role, content: content, records: records} ->
        init = case content do
          nil -> []
          content -> [%{type: "text", text: content}]
        end

        content = Enum.reduce(records, init, fn
          {:tool_use, id, name, input}, content ->
            [%{type: "tool_use", id: id, name: name, input: input} | content]

          {:tool_result, id, _name, output}, content ->
            [%{type: "tool_result", tool_use_id: id, content: output} | content]
        end)

        %{role: to_string(role), content: content}
    end)
  end

  #@spec tool_params(list(Tool.t())) :: list(Anthropix.tool())
  #defp tool_params(tools) do
  #  Enum.map(tools, fn %Tool{} = tool ->
  #    %{
  #      name: tool.name,
  #      description: String.trim(tool.description),
  #      input_schema: %{
  #        type: "object",
  #        properties: Enum.reduce(tool.params, %{}, fn {name, type, description}, props ->
  #          Map.put(props, name, %{
  #            type: to_string(type),
  #            description: String.trim(description),
  #          })
  #        end)
  #      }
  #    }
  #  end)
  #end

end
