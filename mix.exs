defmodule Fluor.Mixfile do
  use Mix.Project

  def project do
    [app: :fluor,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:lager, :slack, :romeo, :exml],
     erl_opts: [parse_transform: "lager_transform"]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      slack: "~>0.4.2",
      websocket_client: [github: "jeremyong/websocket_client"],
      romeo: "~> 0.4.0",
      exml: [github: "esl/exml"],
      exmoji: "~> 0.2.2",
      lager: [github: "basho/lager"]
    ]
  end
end
