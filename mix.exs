defmodule T.MixProject do
  use Mix.Project

  def project do
    [
      app: :t,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {T.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:req, "~> 0.4.0"},
      # JSON parsing
      {:jason, "~> 1.4"},
      # Configuration management
      {:toml, "~> 0.7"},
      # CLI table display
      {:table_rex, "~> 3.1.1"},
      # Text processing
      {:unicode, "~> 1.18"}
    ]
  end

  defp escript do
    [
      main_module: T.CLI,
      name: "t"
    ]
  end
end
