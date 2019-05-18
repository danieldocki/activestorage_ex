defmodule ActivestorageExTest.DiskServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx
  alias ActivestorageEx.DiskService

  describe "DiskService.path_for" do
    test "Directories of returned path are based off key name" do
      path = DiskService.path_for("/", "asdf")

      assert String.contains?(path, "as/df")
    end

    test "Filename of returned path is the key name" do
      key = "asdf"
      path = DiskService.path_for("/", key)

      assert String.ends_with?(path, key)
    end

    test "Returned path is built based off of key name" do
      path = DiskService.path_for("/", "asdf")

      assert "/as/df/asdf" === path
    end

    test "Custom root paths are built into returned path" do
      path = DiskService.path_for("/root/path", "asdf")

      assert "/root/path/as/df/asdf" === path
    end
  end
end
