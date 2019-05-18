defmodule ActivestorageExTest.DiskServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx
  alias ActivestorageEx.DiskService

  setup do
    Application.put_env(:activestorage_ex, :root_path, "/")
  end

  describe "DiskService.download/1" do
    @rails_storage_directory "test/activestorage_ex_rails/storage/"
    @local_key ActivestorageExTest.get_local_upload_key()

    test "Returns a file from a given key as binary" do
      Application.put_env(:activestorage_ex, :root_path, @rails_storage_directory)

      downloaded_file = DiskService.download(@local_key)

      assert is_binary(downloaded_file)
    end

    test "Returns an error if the file cannot be found" do
      Application.put_env(:activestorage_ex, :root_path, "/fake/directory")

      missing_file = DiskService.download(@local_key)

      assert {:error, :enoent} === missing_file
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
      path = DiskService.path_for("asdf")

      assert "/as/df/asdf" === path
    end

    test "Custom root paths are built into returned path" do
      Application.put_env(:activestorage_ex, :root_path, "/root/path")
      path = DiskService.path_for("asdf")

      assert "/root/path/as/df/asdf" === path
    end
  end
end
