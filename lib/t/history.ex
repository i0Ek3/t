defmodule T.History do
  use GenServer
  require Logger

  @history_file ".t_history.json"

  defmodule Entry do
    @derive Jason.Encoder
    defstruct [
      :id,
      :timestamp,
      :source_text,
      :source_lang,
      :target_lang,
      :translated_text,
      :mode,
      :provider
    ]
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_entry(entry) do
    GenServer.call(__MODULE__, {:add_entry, entry})
  end

  def get_recent(count \\ 10) do
    GenServer.call(__MODULE__, {:get_recent, count})
  end

  def search(query) do
    GenServer.call(__MODULE__, {:search, query})
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server callbacks

  @impl true
  def init(_) do
    history = load_history()
    {:ok, history}
  end

  @impl true
  def handle_call({:add_entry, entry}, _from, history) do
    enabled = T.Config.get_nested(["general", "enable_history"], true)

    if enabled do
      max_size = T.Config.get_nested(["general", "max_history_size"], 100)

      new_entry = %Entry{
        id: generate_id(),
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
        source_text: entry.source_text,
        source_lang: entry.source_lang,
        target_lang: entry.target_lang,
        translated_text: entry.translated_text,
        mode: entry.mode,
        provider: entry.provider
      }

      new_history = [new_entry | history] |> Enum.take(max_size)
      save_history(new_history)
      {:reply, :ok, new_history}
    else
      {:reply, :ok, history}
    end
  end


  @impl true
  def handle_call({:get_recent, count}, _from, history) do
    recent = Enum.take(history, count)
    {:reply, recent, history}
  end

  @impl true
  def handle_call({:search, query}, _from, history) do
    query_lower = String.downcase(query)

    results =
      Enum.filter(history, fn entry ->
        String.contains?(String.downcase(entry.source_text), query_lower) ||
          String.contains?(String.downcase(entry.translated_text), query_lower)
      end)

    {:reply, results, history}
  end

  @impl true
  def handle_call(:get_stats, _from, history) do
    stats = %{
      total_translations: length(history),
      languages: get_language_stats(history),
      modes: get_mode_stats(history),
      providers: get_provider_stats(history)
    }

    {:reply, stats, history}
  end

  @impl true
  def handle_cast(:clear, _history) do
    save_history([])
    Logger.info("Translation history cleared")
    {:noreply, []}
  end

  # Private functions

  defp load_history do
    history_path = get_history_path()

    if File.exists?(history_path) do
      case File.read(history_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, data} ->
              Enum.map(data, fn item ->
                struct(Entry, atomize_keys(item))
              end)

            {:error, _} ->
              Logger.warning("Failed to parse history file")
              []
          end

        {:error, _} ->
          []
      end
    else
      []
    end
  end

  defp save_history(history) do
    history_path = get_history_path()

    json_data =
      Enum.map(history, fn entry ->
        Map.from_struct(entry)
      end)
      |> Jason.encode!(pretty: true)

    File.write!(history_path, json_data)
  end

  defp get_history_path do
    home_dir = System.user_home!()
    config_dir = Path.join(home_dir, ".t")
    File.mkdir_p!(config_dir)
    Path.join(config_dir, @history_file)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp get_language_stats(history) do
    history
    |> Enum.flat_map(fn entry -> [entry.source_lang, entry.target_lang] end)
    |> Enum.frequencies()
  end

  defp get_mode_stats(history) do
    history
    |> Enum.map(& &1.mode)
    |> Enum.frequencies()
  end

  defp get_provider_stats(history) do
    history
    |> Enum.map(& &1.provider)
    |> Enum.frequencies()
  end
end
