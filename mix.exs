defmodule Fulib.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fulib,
      name: "Fulib",
      version: "0.1.14",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Lib for elixir",
      source_url: "https://github.com/dev800/fulib",
      homepage_url: "https://github.com/dev800/fulib",
      package: package(),
      docs: [
        extras: ["README.md"],
        main: "readme"
      ]
    ]
  end

  def application do
    [
      mod: {Fulib.Application, []},
      extra_applications: [
        :runtime_tools,
        :redix,
        :shards,
        :nebulex,
        :nebulex_redis_adapter,
        :floki,
        :recase,
        :ranch,
        :cowboy,
        :earmark,
        :jason,
        :yamerl,
        :mbcs,
        :tiny_util,
        :timex,
        :runtime_tools,
        :shorter_maps,
        :logger,
        :logger_file_backend,
        :gettext,
        :gen_stage,
        :liquid
      ]
    ]
  end

  defp deps do
    [
      {:liquid, "~> 0.9"},
      {:nebulex, "~> 1.0"},
      {:gen_stage, "~> 0.14"},
      {:nebulex_redis_adapter, "~> 1.0"},
      {:dataloader, "~> 1.0"},
      {:httpoison, "~> 1.0"},
      {:gettext, "~> 0.13"},
      {:tiny_util, "~> 0.2"},
      {:ecto, "~> 3.0 or ~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:earmark, "~> 1.0"},
      {:floki, "~> 0.20"},
      {:ex_marshal, "~> 0.0.10"},
      {:timex, "~> 3.0"},
      {:cowboy, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:cowlib, "~> 2.0"},
      {:plug, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:yamerl, "~> 0.4"},
      {:shorter_maps, "~> 2.0"},
      {:inch_ex, "~> 0.0", only: :docs},
      {:ex_doc, "~> 0.0", only: :dev, runtime: false},
      {:phoenix_html, "~> 2.0"},
      {:recase, "~> 0.4"},
      {:logger_file_backend, "~> 0.0"}
    ]
  end

  defp package do
    %{
      files: ["lib", "priv", "mix.exs", "README.md", "config/config.exs"],
      maintainers: ["happy"],
      licenses: ["BSD 3-Clause"],
      links: %{"Github" => "https://github.com/dev800/fulib"}
    }
  end
end
