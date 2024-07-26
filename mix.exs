defmodule Sequin.MixProject do
  use Mix.Project

  @github "https://github.com/sequinstream/sequin-elixir"

  def project do
    [
      app: :sequin,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Package
      package: package(),
      description: description(),
      source_url: @github,
      docs: [main: "Sequin"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "An Elixir client for Sequin"
  end

  defp package do
    [
      name: :sequin_client,
      licenses: ["MIT"],
      links: %{GitHub: @github},
      maintainers: ["Anthony Accomazzo", "Carter Pedersen"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:ex_doc, "~> 0.22.0", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
