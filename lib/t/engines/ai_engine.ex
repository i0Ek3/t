defmodule T.Engines.AIEngine do
  @moduledoc """
  AI translation engine, supports multiple AI providers
  """

  require Logger
  alias T.{Config, Language}

  @timeout 60_000

  def translate(text, source_lang, target_lang, opts \\ []) do
    providers = Config.get_nested(["ai", "providers"], ["claude", "cohere"])

    try_providers(providers, text, source_lang, target_lang, opts)
  end

  def translate_with_ollama(text, source_lang, target_lang) do
    config = Config.get_nested(["ai", "ollama"], %{})
    base_url = Map.get(config, "base_url", "http://localhost:11434")
    model = Map.get(config, "model", "llama3")

    url = "#{base_url}/api/generate"

    source_name = Language.get_name(source_lang)
    target_name = Language.get_name(target_lang)

    prompt = """
    Translate the following text from #{source_name} to #{target_name}.
    Only provide the translation, without any explanations or additional text.

    Text to translate: #{text}

    Translation:
    """

    body = %{
      model: model,
      prompt: prompt,
      stream: false
    }

    case Req.post(url, json: body, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated =
          Map.get(response, "response", "")
          |> String.trim()

        result = %{
          translated_text: translated,
          provider: "Ollama (#{model})"
        }

        {:ok, result}

      {:ok, %{status: status}} ->
        {:error, "Ollama returned status #{status}"}

      {:error, reason} ->
        {:error, "Failed to connect to Ollama: #{inspect(reason)}"}
    end
  end

  def explain_words(words, target_lang) do
    providers = Config.get_nested(["ai", "providers"], ["claude"])

    Enum.find_value(providers, {:error, "No AI provider available"}, fn provider ->
      case explain_with_provider(provider, words, target_lang) do
        {:ok, explanations} -> {:ok, explanations}
        {:error, _} -> nil
      end
    end)
  end

  def generate_examples(text, lang, count \\ 2) do
    providers = Config.get_nested(["ai", "providers"], ["claude", "openai", "cohere"])
    ollama_enabled = Config.get_nested(["ai", "ollama", "enabled"], false)
    
    providers = 
      if ollama_enabled and "ollama" not in providers do
        providers ++ ["ollama"]
      else
        providers
      end

    lang_name = Language.get_name(lang)

    Enum.find_value(providers, [], fn provider ->
      case generate_examples_with_provider(provider, text, lang_name, count) do
        {:ok, examples} -> examples
        {:error, _} -> nil
      end
    end)
  end

  # Private functions

  defp try_providers([], _text, _source_lang, _target_lang, _opts) do
    {:error, "All AI providers failed"}
  end

  defp try_providers([provider | rest], text, source_lang, target_lang, opts) do
    case translate_with_provider(provider, text, source_lang, target_lang, opts) do
      {:ok, result} ->
        {:ok, result}

      {:error, :quota_exceeded} ->
        Logger.warning("#{provider} quota exceeded, trying next provider...")
        try_providers(rest, text, source_lang, target_lang, opts)

      {:error, reason} ->
        Logger.warning("#{provider} failed: #{reason}, trying next provider...")
        try_providers(rest, text, source_lang, target_lang, opts)
    end
  end

  defp translate_with_provider("claude", text, source_lang, target_lang, _opts) do
    config = Config.get_nested(["ai", "claude"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "Claude API key not configured"}
    else
      translate_with_claude(text, source_lang, target_lang, config)
    end
  end

  defp translate_with_provider("cohere", text, source_lang, target_lang, _opts) do
    config = Config.get_nested(["ai", "cohere"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "Cohere API key not configured"}
    else
      translate_with_cohere(text, source_lang, target_lang, config)
    end
  end

  defp translate_with_provider("openai", text, source_lang, target_lang, _opts) do
    config = Config.get_nested(["ai", "openai"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "OpenAI API key not configured"}
    else
      translate_with_openai(text, source_lang, target_lang, config)
    end
  end

  defp translate_with_provider(_provider, _text, _source_lang, _target_lang, _opts) do
    {:error, "Unknown provider"}
  end

  # Claude API
  defp translate_with_claude(text, source_lang, target_lang, config) do
    url = Map.get(config, "api_url", "https://api.anthropic.com/v1/messages")
    api_key = Map.get(config, "api_key")
    model = Map.get(config, "model", "claude-sonnet-4-5-20250929")
    max_tokens = Map.get(config, "max_tokens", 2000)

    source_name = Language.get_name(source_lang)
    target_name = Language.get_name(target_lang)

    system_prompt = """
    You are a professional translator. Translate the given text accurately and naturally.
    Preserve the original meaning, tone, and style.
    Only provide the translation without any explanations.
    """

    user_message = """
    Translate the following text from #{source_name} to #{target_name}:

    #{text}
    """

    body = %{
      model: model,
      max_tokens: max_tokens,
      system: system_prompt,
      messages: [
        %{role: "user", content: user_message}
      ]
    }

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated =
          response
          |> get_in(["content"])
          |> List.first(%{})
          |> Map.get("text", "")
          |> String.trim()

        result = %{
          translated_text: translated,
          provider: "Claude (#{model})"
        }

        {:ok, result}

      {:ok, %{status: 429}} ->
        {:error, :quota_exceeded}

      {:ok, %{status: status, body: body}} ->
        error_msg = get_in(body, ["error", "message"]) || "Unknown error"
        Logger.error("Claude API error: #{status} - #{error_msg}")
        {:error, "Claude API error: #{error_msg}"}

      {:error, reason} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  # Cohere API
  defp translate_with_cohere(text, source_lang, target_lang, config) do
    url = Map.get(config, "api_url", "https://api.cohere.ai/v1/generate")
    api_key = Map.get(config, "api_key")
    model = Map.get(config, "model", "command")

    source_name = Language.get_name(source_lang)
    target_name = Language.get_name(target_lang)

    prompt = """
    Translate the following text from #{source_name} to #{target_name}.
    Only provide the translation without any explanations.

    Text: #{text}

    Translation:
    """

    body = %{
      model: model,
      prompt: prompt,
      max_tokens: 1000,
      temperature: 0.3
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated =
          response
          |> get_in(["generations"])
          |> List.first(%{})
          |> Map.get("text", "")
          |> String.trim()

        result = %{
          translated_text: translated,
          provider: "Cohere (#{model})"
        }

        {:ok, result}

      {:ok, %{status: 429}} ->
        {:error, :quota_exceeded}

      {:ok, %{status: status}} ->
        {:error, "Cohere API error: status #{status}"}

      {:error, reason} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  # OpenAI API
  defp translate_with_openai(text, source_lang, target_lang, config) do
    url = Map.get(config, "api_url", "https://api.openai.com/v1/chat/completions")
    api_key = Map.get(config, "api_key")
    model = Map.get(config, "model", "gpt-3.5-turbo")

    source_name = Language.get_name(source_lang)
    target_name = Language.get_name(target_lang)

    body = %{
      model: model,
      messages: [
        %{
          role: "system",
          content:
            "You are a professional translator. Only provide translations without explanations."
        },
        %{
          role: "user",
          content: "Translate from #{source_name} to #{target_name}: #{text}"
        }
      ],
      temperature: 0.3
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated =
          response
          |> get_in(["choices"])
          |> List.first(%{})
          |> get_in(["message", "content"])
          |> String.trim()

        result = %{
          translated_text: translated,
          provider: "OpenAI (#{model})"
        }

        {:ok, result}

      {:ok, %{status: 429}} ->
        {:error, :quota_exceeded}

      {:ok, %{status: status}} ->
        {:error, "OpenAI API error: status #{status}"}

      {:error, reason} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  # AI word explanations
  defp explain_with_provider(provider, words, target_lang) do
    case provider do
      "claude" -> explain_with_claude(words, target_lang)
      _ -> {:error, "Provider not supported for explanations"}
    end
  end

  defp explain_with_claude(words, target_lang) do
    config = Config.get_nested(["ai", "claude"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "Claude API key not configured"}
    else
      url = Map.get(config, "api_url", "https://api.anthropic.com/v1/messages")
      model = Map.get(config, "model", "claude-sonnet-4-5-20250929")

      lang_name = Language.get_name(target_lang)

      prompt = """
      For each of the following #{lang_name} words, provide a brief definition and phonetic transcription (IPA).
      Format your response as JSON array with objects containing: word, phonetic, definition, part_of_speech.

      Words: #{Enum.join(words, ", ")}
      """

      body = %{
        model: model,
        max_tokens: 1500,
        messages: [
          %{role: "user", content: prompt}
        ]
      }

      headers = [
        {"x-api-key", api_key},
        {"anthropic-version", "2023-06-01"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
        {:ok, %{status: 200, body: response}} ->
          text =
            response
            |> get_in(["content"])
            |> List.first(%{})
            |> Map.get("text", "")

          # Try to parse JSON
          case Jason.decode(text) do
            {:ok, explanations} when is_list(explanations) ->
              formatted =
                Enum.map(explanations, fn exp ->
                  %{
                    word: Map.get(exp, "word"),
                    phonetic: Map.get(exp, "phonetic"),
                    definition: Map.get(exp, "definition"),
                    part_of_speech: Map.get(exp, "part_of_speech")
                  }
                end)

              {:ok, formatted}

            _ ->
              {:error, "Failed to parse AI response"}
          end

        _ ->
          {:error, "AI request failed"}
      end
    end
  end

  # AI example sentence generation
  defp generate_examples_with_provider(provider, text, lang_name, count) do
    case provider do
      "claude" -> generate_examples_with_claude(text, lang_name, count)
      "openai" -> generate_examples_with_openai(text, lang_name, count)
      "cohere" -> generate_examples_with_cohere(text, lang_name, count)
      "ollama" -> generate_examples_with_ollama(text, lang_name, count)
      "local" -> generate_examples_with_ollama(text, lang_name, count)
      _ -> {:error, "Provider not supported for examples"}
    end
  end

  defp generate_examples_with_claude(text, lang_name, count) do
    config = Config.get_nested(["ai", "claude"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "Claude API key not configured"}
    else
      url = Map.get(config, "api_url", "https://api.anthropic.com/v1/messages")
      model = Map.get(config, "model", "claude-sonnet-4-5-20250929")

      prompt = """
      Generate #{count} example sentences using the phrase "#{text}" in #{lang_name}.
      Make them practical and natural.
      Format as JSON array with objects containing: source (original sentence), translation (English translation).
      """

      body = %{
        model: model,
        max_tokens: 1000,
        messages: [
          %{role: "user", content: prompt}
        ]
      }

      headers = [
        {"x-api-key", api_key},
        {"anthropic-version", "2023-06-01"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
        {:ok, %{status: 200, body: response}} ->
          text =
            response
            |> get_in(["content"])
            |> List.first(%{})
            |> Map.get("text", "")

          parse_examples_json(text)

        _ ->
          {:error, "AI request failed"}
      end
    end
  end

  defp generate_examples_with_openai(text, lang_name, count) do
    config = Config.get_nested(["ai", "openai"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "OpenAI API key not configured"}
    else
      url = Map.get(config, "api_url", "https://api.openai.com/v1/chat/completions")
      model = Map.get(config, "model", "gpt-3.5-turbo")

      prompt = """
      Generate #{count} example sentences using the phrase "#{text}" in #{lang_name}.
      Make them practical and natural.
      Format as JSON array with objects containing: source (original sentence), translation (English translation).
      """

      body = %{
        model: model,
        messages: [
          %{role: "user", content: prompt}
        ],
        temperature: 0.7
      }

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
        {:ok, %{status: 200, body: response}} ->
          text =
            response
            |> get_in(["choices"])
            |> List.first(%{})
            |> get_in(["message", "content"]) || ""

          parse_examples_json(text)

        _ ->
          {:error, "AI request failed"}
      end
    end
  end

  defp generate_examples_with_cohere(text, lang_name, count) do
    config = Config.get_nested(["ai", "cohere"], %{})
    api_key = Map.get(config, "api_key", "")

    if api_key == "" do
      {:error, "Cohere API key not configured"}
    else
      url = Map.get(config, "api_url", "https://api.cohere.ai/v1/chat")
      model = Map.get(config, "model", "command")

      prompt = """
      Generate #{count} example sentences using the phrase "#{text}" in #{lang_name}.
      Make them practical and natural.
      Format as JSON array with objects containing: source (original sentence), translation (English translation).
      Return ONLY the JSON array.
      """

      body = %{
        model: model,
        message: prompt,
        temperature: 0.3
      }

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
        {:ok, %{status: 200, body: response}} ->
          text = Map.get(response, "text", "")
          parse_examples_json(text)

        _ ->
          {:error, "AI request failed"}
      end
    end
  end

  defp generate_examples_with_ollama(text, lang_name, count) do
    config = Config.get_nested(["ai", "ollama"], %{})
    base_url = Map.get(config, "base_url", "http://localhost:11434")
    model = Map.get(config, "model", "llama3")

    url = "#{base_url}/api/generate"

    prompt = """
    Generate #{count} example sentences using the phrase "#{text}" in #{lang_name}.
    Make them practical and natural.
    Format as JSON array with objects containing: source (original sentence), translation (English translation).
    Return ONLY the JSON array, no other text.
    """

    body = %{
      model: model,
      prompt: prompt,
      stream: false,
      format: "json"
    }

    case Req.post(url, json: body, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        text = Map.get(response, "response", "")
        parse_examples_json(text)

      _ ->
        {:error, "Ollama request failed"}
    end
  end

  defp parse_examples_json(text) do
    # Clean up text to find JSON array
    json_text =
      case Regex.run(~r/\[.*\]/s, text) do
        [match] -> match
        _ -> text
      end

    case Jason.decode(json_text) do
      {:ok, examples} when is_list(examples) -> {:ok, examples}
      _ -> {:error, "Failed to parse examples"}
    end
  end
end
