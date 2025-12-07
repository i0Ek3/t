defmodule T.Output do
  @moduledoc """
  CLI output formatting module
  """

  alias IO.ANSI

  @doc """
  Print translation result
  """
  def print_translation(result) do
    # Source text
    IO.puts("\n#{separator("=")}")
    print_header("📝 Translation Result")
    print_section("Source", result.source_lang)
    IO.puts("  #{colorize(result.source_text, :cyan)}")

    # Translation result
    print_section("Target", result.target_lang)
    IO.puts("  #{colorize(result.translated_text, :green, :bright)}")

    # Word explanations
    if Map.has_key?(result, :word_explanations) && result.word_explanations != [] do
      IO.puts("\n#{separator("-")}")
      print_header("📚 Word Explanations")
      print_word_explanations(result.word_explanations)
    end

    # Examples
    if Map.has_key?(result, :examples) && result.examples != [] do
      IO.puts("\n#{separator("-")}")
      print_header("💡 Examples")
      print_examples(result.examples)
    end

    # Metadata
    if Map.get(result, :show_meta, true) do
      IO.puts("\n#{separator("-")}")
      print_meta(result)
    end

    IO.puts(separator("="))
    IO.puts("")
  end

  @doc """
  Print error message
  """
  def print_error(message) do
    IO.puts("\n#{colorize("❌ Error:", :red, :bright)} #{message}\n")
  end

  @doc """
  Print warning message
  """
  def print_warning(message) do
    IO.puts("#{colorize("⚠️  Warning:", :yellow)} #{message}")
  end

  @doc """
  Print success message
  """
  def print_success(message) do
    IO.puts("#{colorize("✅ Success:", :green)} #{message}")
  end

  @doc """
  Print info message
  """
  def print_info(message) do
    IO.puts("#{colorize("ℹ️  Info:", :blue)} #{message}")
  end

  @doc """
  Print translation history
  """
  def print_history(entries) do
    if entries == [] do
      print_info("No translation history found.")
    else
      IO.puts("\n#{separator("=")}")
      print_header("📜 Translation History")
      IO.puts(separator("="))

      entries
      |> Enum.with_index(1)
      |> Enum.each(fn {entry, index} ->
        print_history_entry(entry, index)
        if index < length(entries), do: IO.puts(separator("-"))
      end)

      IO.puts(separator("="))
      IO.puts("")
    end
  end

  @doc """
  Print statistics
  """
  def print_stats(stats) do
    IO.puts("\n#{separator("=")}")
    print_header("📊 Translation Statistics")
    IO.puts(separator("="))

    IO.puts("\n#{colorize("Total Translations:", :cyan)} #{stats.total_translations}")

    if stats.total_translations > 0 do
      IO.puts("\n#{colorize("Most Used Languages:", :cyan)}")

      stats.languages
      |> Enum.sort_by(fn {_lang, count} -> count end, :desc)
      |> Enum.take(5)
      |> Enum.each(fn {lang, count} ->
        lang_name = T.Language.get_name(lang)
        IO.puts("  • #{lang_name} (#{lang}): #{count}")
      end)

      IO.puts("\n#{colorize("Translation Modes:", :cyan)}")

      Enum.each(stats.modes, fn {mode, count} ->
        IO.puts("  • #{mode}: #{count}")
      end)

      IO.puts("\n#{colorize("Providers Used:", :cyan)}")

      Enum.each(stats.providers, fn {provider, count} ->
        IO.puts("  • #{provider}: #{count}")
      end)
    end

    IO.puts(separator("="))
    IO.puts("")
  end

  @doc """
  Print list of supported languages
  """
  def print_languages do
    languages = T.Language.list_supported()

    IO.puts("\n#{separator("=")}")
    print_header("🌍 Supported Languages")
    IO.puts(separator("="))
    IO.puts("")

    # Display in 4 columns
    languages
    |> Enum.chunk_every(4)
    |> Enum.each(fn chunk ->
      formatted =
        Enum.map(chunk, fn {code, name} ->
          String.pad_trailing("#{code} - #{name}", 25)
        end)
        |> Enum.join("")

      IO.puts("  #{formatted}")
    end)

    IO.puts("\n#{separator("=")}")
    IO.puts("")
  end

  # Private functions

  defp print_header(text) do
    IO.puts("\n#{colorize(text, :magenta, :bright)}")
  end

  defp print_section(label, lang_code) do
    lang_name = T.Language.get_name(lang_code)
    IO.puts("\n#{colorize("#{label}:", :yellow)} #{lang_name} (#{lang_code})")
  end

  defp print_word_explanations(explanations) do
    Enum.each(explanations, fn exp ->
      IO.puts("\n  #{colorize("• #{exp.word}", :cyan, :bright)}")

      if Map.has_key?(exp, :phonetic) && exp.phonetic do
        IO.puts("    #{colorize("Phonetic:", :yellow)} #{exp.phonetic}")
      end

      if Map.has_key?(exp, :definition) && exp.definition do
        IO.puts("    #{colorize("Definition:", :yellow)} #{exp.definition}")
      end

      if Map.has_key?(exp, :part_of_speech) && exp.part_of_speech do
        IO.puts("    #{colorize("Type:", :yellow)} #{exp.part_of_speech}")
      end
    end)
  end

  defp print_examples(examples) do
    Enum.with_index(examples, 1)
    |> Enum.each(fn {example, index} ->
      IO.puts("\n  #{colorize("#{index}.", :yellow)}")

      if is_map(example) do
        if Map.has_key?(example, :source) do
          IO.puts("    #{colorize("→", :cyan)} #{example.source}")
        end

        if Map.has_key?(example, :translation) do
          IO.puts("    #{colorize("→", :green)} #{example.translation}")
        end
      else
        IO.puts("    #{example}")
      end
    end)
  end

  defp print_meta(result) do
    items = []

    items =
      if Map.has_key?(result, :mode) do
        items ++ ["Mode: #{result.mode}"]
      else
        items
      end

    items =
      if Map.has_key?(result, :provider) do
        items ++ ["Provider: #{result.provider}"]
      else
        items
      end

    items =
      if Map.has_key?(result, :duration_ms) do
        items ++ ["Time: #{result.duration_ms}ms"]
      else
        items
      end

    if items != [] do
      meta_text = Enum.join(items, " • ")
      IO.puts("#{colorize(meta_text, :black, :bright)}")
    end
  end

  defp print_history_entry(entry, index) do
    timestamp = format_timestamp(entry.timestamp)

    IO.puts("\n#{colorize("#{index}.", :yellow)} #{colorize(timestamp, :black, :bright)}")

    IO.puts(
      "  #{colorize("From:", :cyan)} #{entry.source_lang} → #{colorize("To:", :green)} #{entry.target_lang}"
    )

    IO.puts(
      "  #{colorize("Source:", :white)} #{String.slice(entry.source_text, 0..50)}#{if String.length(entry.source_text) > 50, do: "...", else: ""}"
    )

    IO.puts(
      "  #{colorize("Translation:", :white)} #{String.slice(entry.translated_text, 0..50)}#{if String.length(entry.translated_text) > 50, do: "...", else: ""}"
    )

    IO.puts(
      "  #{colorize("Mode:", :black, :bright)} #{entry.mode} • #{colorize("Provider:", :black, :bright)} #{entry.provider}"
    )
  end

  defp format_timestamp(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} ->
        # Calculate local offset
        utc = DateTime.utc_now()
        local = NaiveDateTime.local_now()
        offset = NaiveDateTime.diff(local, DateTime.to_naive(utc))
        
        # Apply offset to timestamp
        local_dt = DateTime.add(dt, offset, :second)
        Calendar.strftime(local_dt, "%Y-%m-%d %H:%M:%S")

      _ ->
        timestamp
    end
  end

  defp separator(char) do
    String.duplicate(char, 80)
  end

  defp colorize(text, color, brightness \\ nil) do
    color_code =
      case color do
        :black -> ANSI.black()
        :red -> ANSI.red()
        :green -> ANSI.green()
        :yellow -> ANSI.yellow()
        :blue -> ANSI.blue()
        :magenta -> ANSI.magenta()
        :cyan -> ANSI.cyan()
        :white -> ANSI.white()
        _ -> ""
      end

    brightness_code =
      case brightness do
        :bright -> ANSI.bright()
        :faint -> ANSI.faint()
        _ -> ""
      end

    "#{brightness_code}#{color_code}#{text}#{ANSI.reset()}"
  end
end
