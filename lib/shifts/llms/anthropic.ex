defmodule Shifts.LLMs.Anthropic do
  require Shifts.Tool
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

    dbg opts

    with {:ok, response} <- Anthropix.chat(client(), opts) do
      dbg response
      response
    else
      {:error, error} -> raise error
    end
  end

  @impl true
  def get_message(%{"content" => content_blocks}) do
    Enum.reduce(content_blocks, Message.new(role: :assistant), fn
      %{"type" => "text", "text" => content}, msg ->
        Map.put(msg, :content, content)

      %{"type" => "tool_use", "id" => id, "name" => name, "input" => input}, msg ->
        Message.put_record(msg, Tool.tool_use(id: id, name: name, input: input))

      # ignore any other block types
      _, msg -> msg
    end)
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
    Enum.map(messages, fn
      %Message{role: role, content: content, records: []} ->
        %{role: to_string(role), content: content}

      %Message{role: role, content: content, records: records} ->
        init = case content do
          nil -> []
          content -> [%{type: "text", text: content}]
        end

        content =
          records
          |> Enum.reduce(init, fn
            {:tool_use, id, name, input}, content ->
              [%{type: "tool_use", id: id, name: name, input: input} | content]

            {:tool_result, id, _name, output}, content ->
              [%{type: "tool_result", tool_use_id: id, content: output} | content]
            end)
          |> Enum.reverse()

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
