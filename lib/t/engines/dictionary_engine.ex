defmodule T.Engines.DictionaryEngine do
  @moduledoc """
  Dictionary API engine for word definitions and phonetics
  """

  require Logger
  alias T.Config

  @timeout 10_000

  def lookup(word, lang \\ "en") do
    provider = Config.get_nested(["dictionary", "provider"], "free-dictionary")

    case provider do
      "free-dictionary" ->
        lookup_free_dictionary(word, lang)

      _ ->
        lookup_free_dictionary(word, lang)
    end
  end

  # Free Dictionary API (English only)
  defp lookup_free_dictionary(word, lang) do
    if lang != "en" do
      {:error, "Free Dictionary API only supports English"}
    else
      base_url =
        Config.get_nested(
          ["dictionary", "free_dictionary_url"],
          "https://api.dictionaryapi.dev/api/v2/entries"
        )

      url = "#{base_url}/#{lang}/#{URI.encode(word)}"

      case Req.get(url, receive_timeout: @timeout) do
        {:ok, %{status: 200, body: response}} when is_list(response) ->
          parse_free_dictionary_response(response, word)

        {:ok, %{status: 404}} ->
          {:error, "Word not found"}

        {:ok, %{status: status}} ->
          Logger.warning("Dictionary API returned status: #{status}")
          {:error, "Dictionary lookup failed"}

        {:error, reason} ->
          Logger.error("Dictionary request failed: #{inspect(reason)}")
          {:error, "Network error"}
      end
    end
  end

  defp parse_free_dictionary_response(response, word) do
    entry = List.first(response, %{})

    # Get phonetic
    phonetic = get_phonetic(entry)

    # Get definition
    meanings = Map.get(entry, "meanings", [])
    first_meaning = List.first(meanings, %{})

    part_of_speech = Map.get(first_meaning, "partOfSpeech", "")

    definitions = Map.get(first_meaning, "definitions", [])
    first_def = List.first(definitions, %{})
    definition = Map.get(first_def, "definition", "")

    result = %{
      word: word,
      phonetic: phonetic,
      part_of_speech: part_of_speech,
      definition: definition
    }

    {:ok, result}
  end

  defp get_phonetic(entry) do
    # Try to get phonetic from multiple locations
    cond do
      Map.has_key?(entry, "phonetic") && entry["phonetic"] != "" ->
        entry["phonetic"]

      Map.has_key?(entry, "phonetics") && is_list(entry["phonetics"]) ->
        entry["phonetics"]
        |> Enum.find_value(fn p ->
          text = Map.get(p, "text", "")
          if text != "", do: text, else: nil
        end)

      true ->
        nil
    end
  end
end
