defmodule ActivestorageEx.Service do
  @moduledoc """
    Provides a base set of methods and behaviours that will be used across other service modules
  """

  @acceptable_dispositions ["inline", "attachment"]

  @callback download(key :: String.t()) :: {:ok, binary :: iodata} | {:error, reason :: term}
  @callback stream_download(key :: String.t(), filepath :: String.t()) ::
              {:ok, filepath :: String.t()} | {:error, reason :: term}
  @callback upload(image :: term, key :: String.t()) :: :ok | {:error, reason :: term}
  @callback delete(key :: String.t()) :: :ok | {:error, reason :: term}
  @callback url(key :: String.t(), opts :: map) :: url :: String.t()

  @doc """
    Returns a valid Content-Disposition string from a provided
    disposition type and a filename

  ## Parameters
    - `type`: Disposition type.  Either "attachment" or "inline"
    - `filename`: The name of the given file
    - `opts`: An optional list of config settings for the sanitization method
  """
  def content_disposition_with(type, filename, opts \\ []) do
    "#{cleaned_type(type)}; filename=\"#{sanitize(filename, opts)}\""
  end

  @doc """
    Takes a given filename and normalizes, filters and truncates it.
    if extra breathing room is required (for example to add your own filename
    extension later), you can leave extra room with the padding parameter

  ## Parameters
    - `name`: The filename to sanitize
    - `opts`: Optional sanitization settings.  Can controll padding or fallback filenames
  """
  def sanitize(name, opts \\ []) when is_binary(name) and is_list(opts) do
    padding = Keyword.get(opts, :padding, 0)
    filename_fallback = Keyword.get(opts, :filename_fallback, "file")

    String.trim(name)
    |> String.replace(~r/[[:space:]]+/u, " ")
    |> String.slice(0, 255 - padding)
    |> String.replace(~r/[\x00-\x1F\/\\:\*\?\"<>\|]/u, "")
    |> String.replace(~r/[[:space:]]+/u, " ")
    |> filter_windows_reserved_names(filename_fallback)
    |> filter_dots(filename_fallback)
    |> filename_fallback(filename_fallback)
  end

  defp filename_fallback(name, fallback) do
    case String.length(name) do
      0 -> fallback
      _ -> name
    end
  end

  defp filter_windows_reserved_names(name, fallback) do
    wrn = ~w(CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1
    LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9)

    cond do
      Enum.member?(wrn, String.upcase(name)) -> fallback
      true -> name
    end
  end

  defp filter_dots(name, fallback) do
    cond do
      String.starts_with?(name, ".") -> "#{fallback}#{name}"
      true -> name
    end
  end

  # If type isn't in the list of `acceptable_dispositions`, return "inline"
  defp cleaned_type(type) do
    Enum.find(@acceptable_dispositions, "inline", fn member ->
      type === member
    end)
  end
end
