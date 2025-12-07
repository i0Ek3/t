defmodule T.CLI do
  @moduledoc """
  Main CLI interface module
  """

  alias T.{Translator, History, Output}

  def main(args) do
    # Ensure application is started
    {:ok, _} = Application.ensure_all_started(:t)

    args
    |> parse_args()
    |> process_command()
  end

  defp parse_args(args) do
    # Preprocess args to convert -to, -from, -ai to --to, --from, --ai
    # This allows users to use both -to and --to formats
    preprocessed_args = Enum.map(args, fn arg ->
      cond do
        String.starts_with?(arg, "-to=") -> String.replace_prefix(arg, "-to=", "--to=")
        String.starts_with?(arg, "-from=") -> String.replace_prefix(arg, "-from=", "--from=")
        String.starts_with?(arg, "-ai=") -> String.replace_prefix(arg, "-ai=", "--ai=")
        arg == "-to" -> "--to"
        arg == "-from" -> "--from"
        arg == "-ai" -> "--ai"
        true -> arg
      end
    end)

    {opts, words, _} =
      OptionParser.parse(preprocessed_args,
        strict: [
          to: :string,
          from: :string,
          ai: :string,
          explain: :string,
          
          history: :boolean,
          stats: :boolean,
          clear: :boolean,
          search: :string,
          languages: :boolean,
          help: :boolean,
          version: :boolean
        ],
        aliases: [
          t: :to,
          f: :from,
          h: :help,
          v: :version
        ]
      )

    {opts, words}
  end

  defp process_command({opts, words}) do
    cond do
      Keyword.get(opts, :help) ->
        show_help()

      Keyword.get(opts, :version) ->
        show_version()

      Keyword.get(opts, :languages) ->
        Output.print_languages()

      Keyword.get(opts, :history) ->
        show_history(opts, words)

      Keyword.get(opts, :stats) ->
        show_stats()

      Keyword.get(opts, :clear) ->
        clear_history()

      Keyword.has_key?(opts, :search) ->
        search_history(Keyword.get(opts, :search))

      words != [] ->
        translate_text(words, opts)

      true ->
        Output.print_error("No text provided. Use --help for usage information.")
        System.halt(1)
    end
  end

  defp translate_text(words, opts) do
    text = Enum.join(words, " ")

    target_lang = Keyword.get(opts, :to)
    source_lang = Keyword.get(opts, :from, "auto")
    ai_mode = Keyword.get(opts, :ai)
    explain_source = Keyword.get(opts, :explain, "auto")
    show_examples = Keyword.has_key?(opts, :ai)

    if !target_lang do
      Output.print_error("Target language is required. Use -to=<lang_code> or --to=<lang_code>")
      Output.print_info("Example: t 你好 -to=en")
      Output.print_info("Use --languages to see supported languages")
      System.halt(1)
    end

    translate_opts = [
      target_lang: target_lang,
      source_lang: source_lang,
      ai_mode: ai_mode,
      explanation_source: explain_source,
      show_examples: show_examples
    ]

    case Translator.translate(text, translate_opts) do
      {:ok, result} ->
        Output.print_translation(result)

      {:error, reason} ->
        Output.print_error(reason)
        System.halt(1)
    end
  end

  defp show_history(opts, words) do
    count =
      if Keyword.has_key?(opts, :history) do
        # Check if there's a number in words
        case words do
          [possible_count | _] ->
            case Integer.parse(possible_count) do
              {num, ""} -> num
              _ -> 10
            end
          [] -> 10
        end
      else
        10
      end

    entries = History.get_recent(count)
    Output.print_history(entries)
  end

  defp show_stats do
    stats = History.get_stats()
    Output.print_stats(stats)
  end

  defp clear_history do
    History.clear()
    Output.print_success("Translation history cleared")
  end

  defp search_history(query) do
    if query == "" do
      Output.print_error("Search query cannot be empty")
      System.halt(1)
    end

    results = History.search(query)

    if results == [] do
      Output.print_info("No results found for: #{query}")
    else
      Output.print_info("Found #{length(results)} result(s) for: #{query}")
      Output.print_history(results)
    end
  end

  defp show_help do
    help_text = """
    #{IO.ANSI.cyan()}#{IO.ANSI.bright()}
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    t TRANSLATOR - Command Line Tool                       ║
    ║                           Version 0.2.0                                   ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    #{IO.ANSI.reset()}

    #{IO.ANSI.yellow()}USAGE:#{IO.ANSI.reset()}
      t <text> [options]

    #{IO.ANSI.yellow()}BASIC TRANSLATION:#{IO.ANSI.reset()}
      t 你好 -to=en                    # Translate to English
      t "Hello World" --to=zh          # Translate to Chinese
      t bonjour -to=en -from=fr       # Specify source language

    #{IO.ANSI.yellow()}AI TRANSLATION:#{IO.ANSI.reset()}
      t 我爱你 -to=en -ai=true        # Use AI (Claude/Cohere)
      t "Hello" --to=fr -ai=local      # Use local Ollama model

    #{IO.ANSI.yellow()}OPTIONS:#{IO.ANSI.reset()}
      #{IO.ANSI.green()}-to, --to <lang>#{IO.ANSI.reset()}              Target language (required)
      #{IO.ANSI.green()}-from, --from <lang>#{IO.ANSI.reset()}          Source language (default: auto)
      #{IO.ANSI.green()}-ai <mode>#{IO.ANSI.reset()}                    AI mode: true | local
      #{IO.ANSI.green()}--explain <source>#{IO.ANSI.reset()}            Explanation source: dictionary | ai | auto
    #{IO.ANSI.yellow()}HISTORY & STATS:#{IO.ANSI.reset()}
      #{IO.ANSI.green()}--history [n]#{IO.ANSI.reset()}                 Show last n translations (default: 10)
      #{IO.ANSI.green()}--search <query>#{IO.ANSI.reset()}              Search translation history
      #{IO.ANSI.green()}--stats#{IO.ANSI.reset()}                       Show translation statistics
      #{IO.ANSI.green()}--clear#{IO.ANSI.reset()}                       Clear translation history

    #{IO.ANSI.yellow()}INFORMATION:#{IO.ANSI.reset()}
      #{IO.ANSI.green()}--languages#{IO.ANSI.reset()}                   List all supported languages
      #{IO.ANSI.green()}--help, -h#{IO.ANSI.reset()}                    Show this help message
      #{IO.ANSI.green()}--version, -v#{IO.ANSI.reset()}                 Show version information

    #{IO.ANSI.yellow()}LANGUAGE CODES:#{IO.ANSI.reset()}
      en (English)    zh (Chinese)     es (Spanish)     fr (French)
      de (German)     ja (Japanese)    ko (Korean)      ru (Russian)
      ar (Arabic)     pt (Portuguese)  it (Italian)     ... and 50+ more

      Use #{IO.ANSI.green()}--languages#{IO.ANSI.reset()} to see the complete list.

    #{IO.ANSI.yellow()}EXAMPLES:#{IO.ANSI.reset()}
      # Basic translation
      t 你好世界 -to=en

      # AI translation with explanations
      t "complex sentence" --to=zh -ai=true --explain=ai

      # View history
      t --history 20

      # Search history
      t --search "hello"

      # Show statistics
      t --stats

    #{IO.ANSI.yellow()}CONFIGURATION:#{IO.ANSI.reset()}
      Config file: ~/.t/config.toml
      
      Edit this file to:
      - Set API keys (Claude, Cohere, etc.)
      - Configure Ollama local models
      - Set default preferences
      - Customize output style

    #{IO.ANSI.yellow()}NOTES:#{IO.ANSI.reset()}
      • API mode is free but may have rate limits
      • AI mode requires API keys (free tiers available)
      • Local mode requires Ollama running locally
      • History is saved automatically in ~/.t/

    #{IO.ANSI.cyan()}For more information, visit: https://github.com/i0Ek3/t#{IO.ANSI.reset()}
    """

    IO.puts(help_text)
  end

  defp show_version do
    version_text = """
    #{IO.ANSI.cyan()}#{IO.ANSI.bright()}
    t v0.2.0
    #{IO.ANSI.reset()}

    Built with Elixir #{System.version()}

    Features:
    • Multi-language translation (60+ languages)
    • AI-powered translation (Claude, Cohere, OpenAI)
    • Local model support (Ollama)
    • Word explanations and phonetics
    • Translation history and statistics
    • Beautiful CLI output

    #{IO.ANSI.cyan()}https://github.com/i0Ek3/t#{IO.ANSI.reset()}
    """

    IO.puts(version_text)
  end
end
