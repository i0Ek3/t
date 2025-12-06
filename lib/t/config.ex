defmodule T.Config do
  use GenServer
  require Logger

  @config_file "config.toml"
  @config_example "config.toml.example"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(key, default \\ nil) do
    GenServer.call(__MODULE__, {:get, key, default})
  end

  def get_nested(path, default \\ nil) when is_list(path) do
    GenServer.call(__MODULE__, {:get_nested, path, default})
  end

  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  # Server callbacks

  @impl true
  def init(_) do
    config = load_config()
    {:ok, config}
  end

  @impl true
  def handle_call({:get, key, default}, _from, config) do
    value = Map.get(config, key, default)
    {:reply, value, config}
  end

  @impl true
  def handle_call({:get_nested, path, default}, _from, config) do
    value = get_in(config, path) || default
    {:reply, value, config}
  end

  @impl true
  def handle_call(:reload, _from, _config) do
    new_config = load_config()
    {:reply, :ok, new_config}
  end

  # Private functions

  defp load_config do
    config_path = get_config_path()

    if File.exists?(config_path) do
      case Toml.decode_file(config_path) do
        {:ok, config} ->
          # Logger.info("Configuration file loaded successfully: #{config_path}")
          config

        {:error, reason} ->
          Logger.error("Failed to parse configuration file: #{inspect(reason)}")
          create_default_config()
          default_config()
      end
    else
      Logger.warning("Configuration file not found, creating default config: #{config_path}")
      create_default_config()
      default_config()
    end
  end

  defp get_config_path do
    home_dir = System.user_home!()
    config_dir = Path.join(home_dir, ".t")
    File.mkdir_p!(config_dir)
    Path.join(config_dir, @config_file)
  end

  defp create_default_config do
    config_path = get_config_path()
    example_path = @config_example

    # Copy example config from project root
    if File.exists?(example_path) do
      File.cp!(example_path, config_path)
    else
      # If example file doesn't exist, create basic config
      default_content = """
      [general]
      default_target_language = "en"
      default_source_language = "auto"
      enable_history = true
      max_history_size = 100

      [translation]
      default_mode = "api"
      word_explanation_source = "dictionary"
      show_phonetics = true
      show_examples = true
      example_count = 2

      [api]
      provider = "libretranslate"
      libretranslate_url = "https://libretranslate.com/translate"

      [ai]
      providers = ["claude", "cohere"]

      [ai.claude]
      api_key = ""
      model = "claude-sonnet-4-5-20250929"
      api_url = "https://api.anthropic.com/v1/messages"
      max_tokens = 2000

      [ai.ollama]
      enabled = false
      base_url = "http://localhost:11434"
      model = "llama3"

      [dictionary]
      provider = "free-dictionary"
      free_dictionary_url = "https://api.dictionaryapi.dev/api/v2/entries"

      [output]
      color_theme = "default"
      show_table_borders = true
      show_translation_time = true
      """

      File.write!(config_path, default_content)
    end

    IO.puts("""
    #{IO.ANSI.yellow()}
    ⚠️  Configuration file created: #{config_path}
    Please edit this file to add API keys and customize settings.
    #{IO.ANSI.reset()}
    """)
  end

  defp default_config do
    %{
      "general" => %{
        "default_target_language" => "en",
        "default_source_language" => "auto",
        "enable_history" => true,
        "max_history_size" => 100
      },
      "translation" => %{
        "default_mode" => "api",
        "word_explanation_source" => "dictionary",
        "show_phonetics" => true,
        "show_examples" => true,
        "example_count" => 2
      },
      "api" => %{
        "provider" => "libretranslate"
      },
      "ai" => %{
        "providers" => ["claude"]
      },
      "output" => %{
        "color_theme" => "default"
      }
    }
  end
end
