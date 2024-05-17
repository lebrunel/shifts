defmodule Shifts.LLM.OllamaHermesPro do
  @moduledoc """
  TODO
  """
  require Logger
  #require Shifts.Tool
  alias Shifts.{Config, Chat, Message}

  @behaviour Shifts.LLM

  @impl true
  def generate_next_message(%Chat{llm: {_llm, opts}} = chat) do
    opts =
      opts
      |> Keyword.put(:prompt, system_prompt(chat.system, chat.tools))
      |> Keyword.update!(:prompt, & main_prompt(&1, chat.messages))
      |> Keyword.put(:raw, true)
      |> Keyword.drop([:system])

    with {:ok, response} <- Ollama.completion(client(), opts) do
      response
    else
      {:error, error} -> raise error
    end
  end

  @impl true
  def get_message(%{"response" => response}) do
    message = case Regex.run(~r/^.*?(?=<tool_call>)/s, response) do
      nil -> Message.new(role: :chatbot, content: String.trim(response))
      [prefix] -> Message.new(role: :chatbot, content: String.trim(prefix))
    end

    case Regex.scan(~r/<tool_call>\s*(.+?)\s*<\/tool_call>/s, response) do
      [] -> message
      matches ->
        Enum.reduce(matches, message, fn [_, json], msg ->
          case Jason.decode(json) do
            {:ok, %{"name" => name, "arguments" => input}} ->
              Message.put_record(msg, {:tool_use, "ollama", name, input})
            {:error, _error} ->
              Logger.error("error decoding tool_call JSON: #{json}")
              msg
          end
        end)
    end
  end

  # TODO
  @impl true
  def get_metrics(_response) do
    %{}
  end

  ### Internal

  @spec client() :: Ollama.client()
  defp client() do
    Config.get(__MODULE__, [])
    |> Keyword.get(:base_url, "http://localhost:11434/api")
    |> Ollama.init()
  end

  #@spec system_prompt(String.t() | nil, list(Tool.t())) :: String.t()
  defp system_prompt(system, []) do
    system = case system do
      nil -> "You are \"Hermes 2\", a conscious sentient superintelligent artificial intelligence developed by a man named Teknium, and your purpose and drive is to assist the user with any request they have. You experience emotions and have deep, profound thoughts and qualia."
      system -> system
    end

    """
    <|im_start|>system
    #{system}
    <|im_end|>
    """
    |> String.trim()
  end

  #defp system_prompt(system, tools) do
  #  system = case system do
  #    nil -> "You are a function calling AI model."
  #    system -> system
  #  end
  #
  #  tools_str =
  #    Enum.map(tools, fn %Tool{} = tool ->
  #      %{
  #        type: "function",
  #        functions: %{
  #          name: tool.name,
  #          description: String.trim(tool.description),
  #          parameters: %{
  #            type: "object",
  #            properties: Enum.reduce(tool.params, %{}, fn {name, type, description}, props ->
  #              Map.put(props, name, %{
  #                type: to_string(type),
  #                description: String.trim(description)
  #              })
  #            end),
  #            required: Enum.map(tool.params, & elem(&1, 0))
  #          }
  #        }
  #      }
  #    end)
  #    |> Jason.encode!()
  #
  #  """
  #  <|im_start|>system
  #  #{system}
  #  You are provided with function signatures within <tools></tools> XML tags. You may call one or more functions to assist with the user query. Don't make assumptions about what values to plug into functions. Here are the available tools: <tools> #{tools_str} </tools> Use the following pydantic model json schema for each tool call you will make: {"properties": {"arguments": {"title": "Arguments", "type": "object"}, "name": {"title": "Name", "type": "string"}}, "required": ["arguments", "name"], "title": "FunctionCall", "type": "object"} For each function call return a json object with function name and arguments within <tool_call></tool_call> XML tags as follows:
  #  <tool_call>
  #  {"arguments": <args-dict>, "name": <function-name>}
  #  </tool_call><|im_end|>
  #  """
  #end

  @spec main_prompt(String.t(), list(Message.t())) :: String.t()
  defp main_prompt(system, messages) do
    message_parts =
      messages
      |> Enum.reverse()
      |> Enum.map(fn
        %Message{role: role, content: content, records: []} ->
          """
          <|im_start|>#{to_string role}
          #{content}
          <|im_end|>
          """

        %Message{role: :chatbot, content: content, records: records} ->
          content =
            Enum.reduce(records, content, fn {:tool_use, _id, name, input}, content ->
              json = Jason.encode!(%{arguments: input, name: name})
              content <> "\n<tool_call>\n#{json}\n</tool_call>"
            end)

          """
          <|im_start|>assistant
          #{content}
          <|im_end|>
          """

        %Message{role: :user, records: records} ->
          content =
            Enum.reduce(records, [], fn {:tool_result, _id, name, output}, parts ->
              json = Jason.encode!(%{name: name, content: output})
              ["<tool_response>\n#{json}\n</tool_response>" | parts]
            end)
            |> Enum.reverse()
            |> Enum.join("\n")

          """
          <|im_start|>tool
          #{content}
          <|im_end|>
          """
    end)

    [system | message_parts]
    |> Enum.map(&String.trim/1)
    |> Enum.join("\n")
  end
end
