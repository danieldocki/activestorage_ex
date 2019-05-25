defmodule ActivestorageExTest do
  use ExUnit.Case
  doctest ActivestorageEx

  describe "ActivestorageEx.env/1" do
    test "It reads environment variables" do
      env_value = ActivestorageEx.env(:root_path)
      application_get_value = Application.get_env(:activestorage_ex, :root_path)

      assert application_get_value == env_value
    end
  end

  describe "ActivestorageEx.service/0" do
    test "It returns a service module" do
      assert ActivestorageEx.DiskService = ActivestorageEx.service()
    end
  end

  describe "ActivestorageEx.sign_message/2" do
    test "A signed JWT is returned as a base64 string" do
      token = ActivestorageEx.sign_message(%{})

      assert {:ok, _} = Base.url_decode64(token)
    end

    test "A JWT is returned with no expiration" do
      token = ActivestorageEx.sign_message(%{})

      assert {:ok, _} = ActivestorageEx.verify_message(token)
    end

    test "A JWT with no expiration and the same payload always returns the same result" do
      token_1 = ActivestorageEx.sign_message(%{foo: "bar"})
      token_2 = ActivestorageEx.sign_message(%{foo: "bar"})

      assert token_1 == token_2
    end

    test "The JWT can be given an expiration in the future and be verified" do
      token = ActivestorageEx.sign_message(%{}, 60)

      assert {:ok, _} = ActivestorageEx.verify_message(token)
    end

    test "The JWT cannot be verified if the expiration time has passed" do
      token = ActivestorageEx.sign_message(%{}, -60)

      assert {:error, :token_expired} = ActivestorageEx.verify_message(token)
    end
  end

  describe "ActivestorageEx.verify_message/1" do
    # Most use cases are captured in ActivestorageEx.sign_message/2 tests
    test "A generic error is returned for an invalid JWT" do
      bad_token =
        JWT.sign(%{}, %{key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"})
        |> Base.url_encode64()

      assert {:error, :invalid_token} = ActivestorageEx.verify_message(bad_token)
    end
  end
end
