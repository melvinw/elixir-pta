defmodule PTA.MixProject do
  use Mix.Project

  def project do
    [
      app: :email2pta,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gen_smtp, "~> 1.0"}
    ]
  end
end
