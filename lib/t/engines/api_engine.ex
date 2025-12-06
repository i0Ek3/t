defmodule T.Engines.APIEngine do
  @moduledoc """
  Free translation API engine
  Supports LibreTranslate and MyMemory
  """

  require Logger
  alias T.Config

  @timeout 10_000

  def translate(text, source_lang, target_lang) do
    provider = Config.get_nested(["api", "provider"], "libretranslate")

    case provider do
      "libretranslate" ->
        translate_with_libretranslate(text, source_lang, target_lang)

      "mymemory" ->
        translate_with_mymemory(text, source_lang, target_lang)

      "google" ->
        translate_with_google(text, source_lang, target_lang)

      _ ->
        # Default to LibreTranslate
        translate_with_libretranslate(text, source_lang, target_lang)
    end
  end

  # LibreTranslate API
  defp translate_with_libretranslate(text, source_lang, target_lang) do
    url = Config.get_nested(["api", "libretranslate_url"], "https://libretranslate.com/translate")

    body = %{
      q: text,
      source: source_lang,
      target: target_lang,
      format: "text"
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, json: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated = Map.get(response, "translatedText", "")
        {:ok, translated, "LibreTranslate"}

      {:ok, %{status: status, body: body}} ->
        Logger.error("LibreTranslate API error: #{status} - #{inspect(body)}")
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        Logger.error("LibreTranslate request failed: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  # MyMemory API
  defp translate_with_mymemory(text, source_lang, target_lang) do
    api_key = Config.get_nested(["api", "mymemory_api_key"], "")

    # MyMemory uses langpair parameter
    langpair = "#{source_lang}|#{target_lang}"

    url = "https://api.mymemory.translated.net/get"

    query_params = [
      q: text,
      langpair: langpair
    ]

    query_params =
      if api_key != "" do
        query_params ++ [key: api_key]
      else
        query_params
      end

    case Req.get(url, params: query_params, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} ->
        translated = get_in(response, ["responseData", "translatedText"]) || ""
        {:ok, translated, "MyMemory"}

      {:ok, %{status: status, body: body}} ->
        Logger.error("MyMemory API error: #{status} - #{inspect(body)}")
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        Logger.error("MyMemory request failed: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  # Google Translate (unofficial, via public API)
  defp translate_with_google(text, source_lang, target_lang) do
    url = "https://translate.googleapis.com/translate_a/single"

    params = [
      client: "gtx",
      sl: source_lang,
      tl: target_lang,
      dt: "t",
      q: text
    ]

    case Req.get(url, params: params, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: response}} when is_list(response) ->
        # Google returns format: [[[translated_text, original_text, ...]]]
        translated =
          response
          |> List.first([])
          |> Enum.filter(&is_list/1)
          |> Enum.map(fn item -> List.first(item, "") end)
          |> Enum.join("")

        {:ok, translated, "Google Translate"}

      {:ok, %{status: status}} ->
        Logger.error("Google Translate API error: #{status}")
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        Logger.error("Google Translate request failed: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end
end
