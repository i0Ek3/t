defmodule T.Language do
  @moduledoc """
  Language code validation and conversion module
  Supports ISO 639-1 language codes
  """

  @languages %{
    # Common languages
    "en" => "English",
    "zh" => "Chinese",
    "zh-CN" => "Chinese (Simplified)",
    "zh-TW" => "Chinese (Traditional)",
    "es" => "Spanish",
    "fr" => "French",
    "de" => "German",
    "it" => "Italian",
    "ja" => "Japanese",
    "ko" => "Korean",
    "ru" => "Russian",
    "ar" => "Arabic",
    "pt" => "Portuguese",
    "hi" => "Hindi",
    "tr" => "Turkish",
    "nl" => "Dutch",
    "pl" => "Polish",
    "sv" => "Swedish",
    "da" => "Danish",
    "fi" => "Finnish",
    "no" => "Norwegian",
    "cs" => "Czech",
    "el" => "Greek",
    "he" => "Hebrew",
    "th" => "Thai",
    "vi" => "Vietnamese",
    "id" => "Indonesian",
    "ms" => "Malay",
    "uk" => "Ukrainian",
    "ro" => "Romanian",
    "hu" => "Hungarian",
    "bg" => "Bulgarian",
    "sr" => "Serbian",
    "hr" => "Croatian",
    "sk" => "Slovak",
    "sl" => "Slovenian",
    "lt" => "Lithuanian",
    "lv" => "Latvian",
    "et" => "Estonian",
    "ca" => "Catalan",
    "af" => "Afrikaans",
    "sq" => "Albanian",
    "hy" => "Armenian",
    "az" => "Azerbaijani",
    "eu" => "Basque",
    "be" => "Belarusian",
    "bn" => "Bengali",
    "bs" => "Bosnian",
    "cy" => "Welsh",
    "eo" => "Esperanto",
    "fa" => "Persian",
    "ga" => "Irish",
    "gl" => "Galician",
    "ka" => "Georgian",
    "gu" => "Gujarati",
    "ha" => "Hausa",
    "is" => "Icelandic",
    "kn" => "Kannada",
    "kk" => "Kazakh",
    "km" => "Khmer",
    "ku" => "Kurdish",
    "ky" => "Kyrgyz",
    "lo" => "Lao",
    "la" => "Latin",
    "mk" => "Macedonian",
    "mg" => "Malagasy",
    "ml" => "Malayalam",
    "mr" => "Marathi",
    "mn" => "Mongolian",
    "my" => "Myanmar",
    "ne" => "Nepali",
    "pa" => "Punjabi",
    "si" => "Sinhala",
    "so" => "Somali",
    "sw" => "Swahili",
    "tg" => "Tajik",
    "ta" => "Tamil",
    "te" => "Telugu",
    "ur" => "Urdu",
    "uz" => "Uzbek",
    "yi" => "Yiddish",
    "zu" => "Zulu",
    "auto" => "Auto Detect"
  }

  # Language code alias mapping
  @aliases %{
    "sp" => "es",
    "cn" => "zh",
    "jp" => "ja",
    "kr" => "ko"
  }

  def valid?(code) when is_binary(code) do
    normalized = normalize_code(code)
    Map.has_key?(@languages, normalized)
  end

  def normalize_code(code) when is_binary(code) do
    lower_code = String.downcase(code)
    Map.get(@aliases, lower_code, lower_code)
  end

  def get_name(code) when is_binary(code) do
    normalized = normalize_code(code)
    Map.get(@languages, normalized, "Unknown")
  end

  def list_supported do
    @languages
    |> Enum.sort_by(fn {_code, name} -> name end)
  end

  def search(query) when is_binary(query) do
    query_lower = String.downcase(query)

    @languages
    |> Enum.filter(fn {code, name} ->
      String.contains?(String.downcase(code), query_lower) ||
        String.contains?(String.downcase(name), query_lower)
    end)
    |> Enum.sort_by(fn {_code, name} -> name end)
  end

  def suggest_similar(invalid_code) when is_binary(invalid_code) do
    invalid_lower = String.downcase(invalid_code)

    @languages
    |> Map.keys()
    |> Enum.filter(fn code ->
      String.jaro_distance(code, invalid_lower) > 0.7
    end)
    |> Enum.take(3)
  end

  def detect_language(text) when is_binary(text) do
    # 简单的语言检测（基于字符范围）
    cond do
      has_chinese_chars?(text) -> "zh"
      has_japanese_chars?(text) -> "ja"
      has_korean_chars?(text) -> "ko"
      has_arabic_chars?(text) -> "ar"
      has_cyrillic_chars?(text) -> "ru"
      has_greek_chars?(text) -> "el"
      has_thai_chars?(text) -> "th"
      true -> "en"
    end
  end

  # Private helper functions - using String.to_charlist and Unicode character ranges

  defp has_chinese_chars?(text) do
    # Convert to charlist and check character codepoint ranges
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0x4E00 and char <= 0x9FFF end)
  end

  defp has_japanese_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char ->
      # Hiragana
      # Katakana
      (char >= 0x3040 and char <= 0x309F) or
        (char >= 0x30A0 and char <= 0x30FF)
    end)
  end

  defp has_korean_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0xAC00 and char <= 0xD7AF end)
  end

  defp has_arabic_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0x0600 and char <= 0x06FF end)
  end

  defp has_cyrillic_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0x0400 and char <= 0x04FF end)
  end

  defp has_greek_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0x0370 and char <= 0x03FF end)
  end

  defp has_thai_chars?(text) do
    text
    |> String.to_charlist()
    |> Enum.any?(fn char -> char >= 0x0E00 and char <= 0x0E7F end)
  end
end
