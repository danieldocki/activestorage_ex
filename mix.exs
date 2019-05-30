defmodule ActivestorageEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :activestorage_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yajwt, "~> 1.0"},
      {:mogrify, "~> 0.7.2"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      # For AWS S3
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"}
    ]
  end
end
