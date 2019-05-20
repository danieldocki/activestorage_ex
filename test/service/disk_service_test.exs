defmodule ActivestorageExTest.DiskServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx.DiskService
  alias ActivestorageEx.DiskService

  @rails_storage_directory "test/activestorage_ex_rails/storage/"

  setup do
    Application.put_env(:activestorage_ex, :root_path, @rails_storage_directory)
    Application.put_env(:activestorage_ex, :asset_host, "")
  end

  describe "DiskService.download/1" do
    @local_key ActivestorageExTest.get_local_upload_key()

    test "Returns a file from a given key as binary" do
      downloaded_file = DiskService.download(@local_key)

      assert is_binary(downloaded_file)
    end

    test "Returns an error if the file cannot be found" do
      Application.put_env(:activestorage_ex, :root_path, "/fake/directory")

      missing_file = DiskService.download(@local_key)

      assert {:error, :enoent} == missing_file
    end
  end

  describe "DiskService.path_for/1" do
    test "Directories of returned path are based off key name" do
      path = DiskService.path_for("asdf")

      assert String.contains?(path, "as/df")
    end

    test "Filename of returned path is the key name" do
      key = "asdf"
      path = DiskService.path_for(key)

      assert String.ends_with?(path, key)
    end

    test "Returned path is built based off of key name" do
      Application.put_env(:activestorage_ex, :root_path, "/")
      path = DiskService.path_for("asdf")

      assert "/as/df/asdf" == path
    end

    test "Custom root paths are built into returned path" do
      Application.put_env(:activestorage_ex, :root_path, "/root/path")
      path = DiskService.path_for("asdf")

      assert "/root/path/as/df/asdf" == path
    end
  end

  describe "DiskService.url/2" do
    test "A signed JWT is returned with no expiration" do
      token = jwt_from_url("", %{filename: ""})

      assert {:ok, _} = JWT.verify(token, %{key: jwt_secret()})
    end

    test "The JWT can be given an expiration in the future and be verified" do
      token = jwt_from_url("", %{filename: "", token_duration: 60})

      assert {:ok, _} = JWT.verify(token, %{key: jwt_secret()})
    end

    test "The JWT cannot be verified if the expiration time has passed" do
      token = jwt_from_url("", %{filename: "", token_duration: -60})

      assert {:error, [exp: _]} = JWT.verify(token, %{key: jwt_secret()})
    end

    test "The JWT contains disposition + filename, key, and content_type" do
      {:ok, claims} =
        jwt_from_url("test_key", %{
          filename: "test.png",
          disposition: "inline",
          content_type: "image/png"
        })
        |> JWT.verify(%{key: jwt_secret()})

      assert claims["key"] == "test_key"
      assert claims["disposition"] == "inline; filename=\"test.png\""
      assert claims["content_type"] == "image/png"
    end

    test "A custom host can be specified" do
      Application.put_env(:activestorage_ex, :asset_host, "custom.host")

      url = DiskService.url("", %{filename: ""})

      assert String.starts_with?(url, "custom.host/")
    end

    test "The filename is present in the final URL" do
      url = DiskService.url("", %{filename: "test.png"})

      assert String.contains?(url, "/test.png")
    end

    test "The full disposition is present in the final URL" do
      url =
        DiskService.url("", %{
          filename: "test.png",
          disposition: "inline"
        })

      assert String.contains?(url, "disposition=inline%3B+filename%3D%22test.png%22")
    end

    test "The content_type is present in the final URL" do
      url =
        DiskService.url("", %{
          filename: "",
          content_type: "image/png"
        })

      assert String.contains?(url, "content_type=image%2Fpng")
    end

    test "Extra opts are discarded" do
      url =
        DiskService.url("", %{
          filename: "",
          custom_opt: "something_bad"
        })

      refute String.contains?(url, "something_bad")
    end

    defp jwt_from_url(token, opts) do
      {:ok, token} =
        DiskService.url(token, opts)
        |> String.split("/")
        |> Enum.fetch(3)

      token
    end

    defp jwt_secret() do
      ActivestorageEx.env(:jwt_secret)
    end
  end
end
