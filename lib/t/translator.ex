defmodule T.Translator do
  @moduledoc """
  Main translation engine module, coordinates all translation services
  """

  alias T.{Config, Language, History, Output}
  alias T.Engines.{APIEngine, AIEngine, DictionaryEngine}

  @doc """
  Execute translation
  """
  def translate(text, opts \\ []) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, validated_opts} <- validate_options(text, opts),
         {:ok, result} <- do_translate(text, validated_opts) do
      duration = System.monotonic_time(:millisecond) - start_time

      # Add metadata
      result =
        Map.merge(result, %{
          duration_ms: duration,
          timestamp: DateTime.utc_now()
        })

      # Save to history
      save_to_history(result)

      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp validate_options(text, opts) do
    cond do
      String.trim(text) == "" ->
        {:error, "Text cannot be empty"}

      true ->
        target_lang =
          Keyword.get(opts, :target_lang) ||
            Config.get_nested(["general", "default_target_language"], "en")

        source_lang =
          Keyword.get(opts, :source_lang) ||
            Config.get_nested(["general", "default_source_language"], "auto")

        # Validate language codes
        target_lang = Language.normalize_code(target_lang)
        source_lang = Language.normalize_code(source_lang)

        cond do
          not Language.valid?(target_lang) ->
            suggestions = Language.suggest_similar(target_lang)

            suggestion_text =
              if suggestions != [],
                do: " Did you mean: #{Enum.join(suggestions, ", ")}?",
                else: ""

            {:error, "Invalid target language: #{target_lang}.#{suggestion_text}"}

          source_lang != "auto" && not Language.valid?(source_lang) ->
            {:error, "Invalid source language: #{source_lang}"}

          true ->
            # Language validation passed, continue processing
            nil
        end

        # If previous checks returned error, return directly
        case {Language.valid?(target_lang), source_lang == "auto" || Language.valid?(source_lang)} do
          {false, _} ->
            suggestions = Language.suggest_similar(target_lang)

            suggestion_text =
              if suggestions != [],
                do: " Did you mean: #{Enum.join(suggestions, ", ")}?",
                else: ""

            {:error, "Invalid target language: #{target_lang}.#{suggestion_text}"}

          {true, false} ->
            {:error, "Invalid source language: #{source_lang}"}

          {true, true} ->
            # Auto-detect source language
            final_source_lang =
              if source_lang == "auto" do
                Language.detect_language(text)
              else
                source_lang
              end

            validated_opts = [
              target_lang: target_lang,
              source_lang: final_source_lang,
              mode: Keyword.get(opts, :mode, :auto),
              ai_mode: Keyword.get(opts, :ai_mode, nil),
              show_explanations: Keyword.get(opts, :show_explanations, true),
              show_examples: Keyword.get(opts, :show_examples, true),
              explanation_source: Keyword.get(opts, :explanation_source, :auto)
            ]

            {:ok, validated_opts}
        end
    end
  end

  defp do_translate(text, opts) do
    mode = determine_mode(opts[:mode], opts[:ai_mode])

    case mode do
      :api ->
        translate_with_api(text, opts)

      :ai ->
        translate_with_ai(text, opts)

      :local ->
        translate_with_local(text, opts)
    end
  end

  defp determine_mode(mode, ai_mode) do
    cond do
      ai_mode == "local" || ai_mode == :local ->
        :local

      ai_mode == "true" || ai_mode == true || mode == :ai ->
        :ai

      true ->
        default_mode = Config.get_nested(["translation", "default_mode"], "api")
        if default_mode == "ai", do: :ai, else: :api
    end
  end

  defp translate_with_api(text, opts) do
    case APIEngine.translate(text, opts[:source_lang], opts[:target_lang]) do
      {:ok, translated_text, provider} ->
        result = %{
          source_text: text,
          source_lang: opts[:source_lang],
          target_lang: opts[:target_lang],
          translated_text: translated_text,
          mode: "api",
          provider: provider
        }

        # Add word explanations and examples
        result = maybe_add_explanations(result, opts)
        result = maybe_add_examples(result, opts)

        {:ok, result}

      {:error, reason} ->
        {:error, "API translation failed: #{reason}"}
    end
  end

  defp translate_with_ai(text, opts) do
    case AIEngine.translate(text, opts[:source_lang], opts[:target_lang], opts) do
      {:ok, result} ->
        result =
          Map.merge(result, %{
            source_text: text,
            source_lang: opts[:source_lang],
            target_lang: opts[:target_lang],
            mode: "ai"
          })

        {:ok, result}

      {:error, :quota_exceeded, provider} ->
        Output.print_warning("#{provider} quota exceeded, falling back to API translation...")
        translate_with_api(text, opts)

      {:error, reason} ->
        Output.print_warning(
          "AI translation failed: #{reason}, falling back to API translation..."
        )

        translate_with_api(text, opts)
    end
  end

  defp translate_with_local(text, opts) do
    ollama_config = Config.get_nested(["ai", "ollama"], %{})

    if Map.get(ollama_config, "enabled", false) do
      case AIEngine.translate_with_ollama(text, opts[:source_lang], opts[:target_lang]) do
        {:ok, result} ->
          result =
            Map.merge(result, %{
              source_text: text,
              source_lang: opts[:source_lang],
              target_lang: opts[:target_lang],
              mode: "local"
            })

          {:ok, result}

        {:error, reason} ->
          Output.print_warning(
            "Local model translation failed: #{reason}, falling back to API translation..."
          )

          translate_with_api(text, opts)
      end
    else
      Output.print_warning(
        "Local Ollama model not configured, falling back to API translation..."
      )

      translate_with_api(text, opts)
    end
  end

  defp maybe_add_explanations(result, opts) do
    if opts[:show_explanations] do
      source =
        opts[:explanation_source] ||
          Config.get_nested(["translation", "word_explanation_source"], "dictionary")

      explanations =
        case source do
          "ai" ->
            get_ai_explanations(result)

          "dictionary" ->
            get_dictionary_explanations(result)

          _ ->
            # Auto-select: prefer dictionary, fallback to AI if failed
            case get_dictionary_explanations(result) do
              [] -> get_ai_explanations(result)
              exps -> exps
            end
        end

      Map.put(result, :word_explanations, explanations)
    else
      result
    end
  end

  defp maybe_add_examples(result, opts) do
    if opts[:show_examples] do
      example_count = Config.get_nested(["translation", "example_count"], 2)

      examples =
        AIEngine.generate_examples(
          result.translated_text,
          result.target_lang,
          example_count
        )

      Map.put(result, :examples, examples)
    else
      result
    end
  end

  defp get_dictionary_explanations(result) do
    # Determine which text to explain. 
    # If target is English, explain translated text.
    # If source is English (or target is not English), explain source text.
    # We prefer explaining English words as our dictionary provider is English-only.
    
    {text_to_explain, lang_for_lookup} = 
      if result.target_lang == "en" do
        {result.translated_text, "en"}
      else
        {result.source_text, "en"}
      end

    # Extract difficult words (simple implementation: words longer than 6 letters)
    words = extract_difficult_words(text_to_explain)

    words
    # Maximum 3 difficult words
    |> Enum.take(3)
    |> Enum.flat_map(fn word ->
      case DictionaryEngine.lookup(word, lang_for_lookup) do
        {:ok, explanation} -> [explanation]
        {:error, _} -> []
      end
    end)
  end

  defp get_ai_explanations(result) do
    words = extract_difficult_words(result.translated_text)

    case AIEngine.explain_words(words, result.target_lang) do
      {:ok, explanations} -> explanations
      {:error, _} -> []
    end
  end

  defp extract_difficult_words(text) do
    words =
      text
      |> String.split(~r/[^\p{L}]+/u, trim: true)

    if length(words) == 1 do
      words
    else
      words
      |> Enum.filter(fn word -> String.length(word) > 6 end)
      |> Enum.take(5)
      |> Enum.uniq()
    end
  end

  defp save_to_history(result) do
    entry = %{
      source_text: result.source_text,
      source_lang: result.source_lang,
      target_lang: result.target_lang,
      translated_text: result.translated_text,
      mode: result.mode,
      provider: result.provider || "unknown"
    }

    History.add_entry(entry)
  end
end
