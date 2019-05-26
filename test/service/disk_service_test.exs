defmodule ActivestorageExTest.DiskServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx.DiskService
  alias ActivestorageEx.DiskService

  @rails_storage_directory "external/activestorage_ex_rails/storage/"
  @local_key TestHelper.get_local_upload_key()

  setup do
    Application.put_env(:activestorage_ex, :root_path, @rails_storage_directory)
    Application.put_env(:activestorage_ex, :asset_host, "http://localhost.test")
  end

  describe "DiskService.download/1" do
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

  describe "DiskService.stream_download/2" do
    test "An image is downloaded to the given filepath" do
      filepath = "test/files/streamed.jpg"
      DiskService.stream_download(@local_key, filepath)

      assert File.exists?(filepath)

      File.rm(filepath)
    end
  end

  describe "DiskService.upload/2" do
    test "An image is sucessfully saved to disk" do
      Application.put_env(:activestorage_ex, :root_path, "test/files")
      image = Mogrify.open("test/files/image.jpg")
      key = "test_key"

      DiskService.upload(image, key)

      assert File.exists?(DiskService.path_for(key))

      File.rm(DiskService.path_for(key))
    end

    test "Image directory is created if it doesn't exist" do
      Application.put_env(:activestorage_ex, :root_path, "test/files")
      image = Mogrify.open("test/files/image.jpg")
      key = "non_existant_key"

      refute File.exists?(Path.dirname(DiskService.path_for(key)))

      DiskService.upload(image, key)

      assert File.exists?(Path.dirname(DiskService.path_for(key)))
      File.rm_rf(Path.dirname(DiskService.path_for(key)))
    end
  end

  describe "DiskService.path_for/1" do
    test "Directories of returned path are based off key name" do
      path = DiskService.path_for("asdf")

      assert String.contains?(path, "as/df")
    end

    test "Directories of variants are represented correctly" do
      path = DiskService.path_for("variant/blob_key/variant_key")

      assert String.contains?(path, "/va/ri/variant/blob_key/variant_key")
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
    test "The JWT contains disposition + filename, key, and content_type" do
      {:ok, claims} =
        jwt_from_url("test_key", %{
          filename: "test.png",
          disposition: "inline",
          content_type: "image/png"
        })
        |> ActivestorageEx.verify_message()

      assert claims["key"] == "test_key"
      assert claims["disposition"] == "inline; filename=\"test.png\""
      assert claims["content_type"] == "image/png"
    end

    test "A custom host can be specified" do
      Application.put_env(:activestorage_ex, :asset_host, "http://custom.host")

      url = DiskService.url("", %{filename: ""})

      assert String.starts_with?(url, "http://custom.host/")
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

    defp jwt_from_url(key, opts) do
      {:ok, jwt} =
        DiskService.url(key, opts)
        |> String.split("/")
        |> Enum.fetch(5)

      jwt
    end
  end

  describe "DiskService.exist?/1" do
    test "Returns true if a file with a given key exists" do
      assert DiskService.exist?(@local_key)
    end

    test "Returns false if a file with a given key doesn't exist" do
      refute DiskService.exist?("not-a-real-key")
    end
  end
end
