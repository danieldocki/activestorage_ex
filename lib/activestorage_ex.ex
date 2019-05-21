defmodule ActivestorageEx do
  def env(name) do
    Application.get_env(:activestorage_ex, name)
  end

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

  def verify_message(encoded_token) do
    decoded_token = Base.url_decode64!(encoded_token)

    case JWT.verify(decoded_token, %{key: ActivestorageEx.env(:jwt_secret)}) do
      {:ok, claims} -> {:ok, claims}
      {:error, exp: _} -> {:error, :token_expired}
      _ -> {:error, :invalid_token}
    end
  end
end
