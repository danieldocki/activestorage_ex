defmodule ActivestorageEx do
  @moduledoc """
    The base `ActivestorageEx` module provides helper methods as well
    as some convenience methods for external use
  """

  @doc """
    Returns a given environment/config variable by its name

  ## Parameters
    - `name`: The environment variable you want to fetch
  """
  def env(name) do
    Application.get_env(:activestorage_ex, name)
  end

  @doc """
    Returns the service module specified in config
  """
  def service do
    env(:service)
  end

  @doc """
    Returns a URL-safe base64 encoded string representing a JWT.
    An expiration can optionally be specified

  ## Parameters
    - `payload`: The Map you want to encode
    - `token_duration`: The token expiration.  Leave `nil` to generate
      a non-expiring token
  """
  def sign_message(payload, token_duration \\ nil) do
    current_time = DateTime.utc_now() |> DateTime.to_unix()

    payload_with_expiration =
      case token_duration do
        nil -> payload
        _ -> Map.put(payload, :exp, current_time + token_duration)
      end

    JWT.sign(payload_with_expiration, %{key: ActivestorageEx.env(:jwt_secret)})
    |> Base.url_encode64()
  end

  @doc """
    Decode a list of claims as encoded by the given JWT

    Returns `{:ok, claims} | {:error, error}`
  ## Parameters
    - `encoded_token`: The token you want to decode
  """
  def verify_message(encoded_token) do
    decoded_token = Base.url_decode64!(encoded_token)

    case JWT.verify(decoded_token, %{key: ActivestorageEx.env(:jwt_secret)}) do
      {:ok, claims} -> {:ok, claims}
      {:error, exp: _} -> {:error, :token_expired}
      _ -> {:error, :invalid_token}
    end
  end
end
