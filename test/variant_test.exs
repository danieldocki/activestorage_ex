defmodule ActivestorageExTest.VariantTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variant
  alias ActivestorageEx.Blob
  alias ActivestorageEx.Variant
  alias ActivestorageEx.DiskService

  @local_key TestHelper.get_local_upload_key()

  @mock_blob %Blob{
    key: @local_key,
    filename: "foo.png",
    content_type: "image/png"
  }

  @mock_transformations [%{resize: "50x50^"}]

  @mock_variant struct(
                  Variant,
                  Map.from_struct(@mock_blob)
                  |> Map.put(:transformations, @mock_transformations)
                )

  @rails_storage_directory "external/activestorage_ex_rails/storage/"

  setup do
    Application.put_env(:activestorage_ex, :root_path, @rails_storage_directory)
  end

  describe "Variant.key/2" do
    test "A variant key includes the root blob's key" do
      variant_key = Variant.key(@mock_blob, [])

      assert String.contains?(variant_key, @local_key)
    end

    test "A variant key includes a unique hash of the transformations" do
      variant_key_1 = Variant.key(@mock_blob, [%{resize: "1x1"}])
      variant_key_2 = Variant.key(@mock_blob, [%{extent: "1x1"}])

      refute variant_key_1 == variant_key_2
    end
  end

  describe "Variant.key/1" do
    test "A variant can be provided instead of a blob + transformation" do
      assert Variant.key(@mock_variant)
    end
  end

  describe "Variant.processed/2" do
    test "Returns a variant directly if it exists" do
      Application.put_env(:activestorage_ex, :root_path, "test/files/")
      key = Variant.key(@mock_blob, @mock_transformations)

      assert_file_unchanged(key, fn ->
        Variant.processed(@mock_blob, @mock_transformations)
      end)
    end

    test "Creates a new variant if it doesn't exist" do
      Application.put_env(:activestorage_ex, :root_path, "test/files/")
      updated_blob = %Blob{@mock_blob | key: "TFJvzLbsfxgFnMY52mz65p5j"}
      key = Variant.key(updated_blob, @mock_transformations)

      assert_file_created(key, fn ->
        Variant.processed(updated_blob, @mock_transformations)
      end)

      remove_file_by_key(key)
    end

    test "New variants have transformations applied" do
      Application.put_env(:activestorage_ex, :root_path, "test/files/")
      updated_blob = %Blob{@mock_blob | key: "TFJvzLbsfxgFnMY52mz65p5j"}
      custom_transformations = [%{resize: "75x75^"}, %{extent: "75x75"}]
      key = Variant.key(updated_blob, custom_transformations)

      Variant.processed(updated_blob, custom_transformations)

      image_stats = Mogrify.open(DiskService.path_for(key)) |> Mogrify.verbose()

      assert {75, 75} = {image_stats.height, image_stats.width}

      remove_file_by_key(key)
    end

    defp assert_file_unchanged(key, callable) do
      before_file = File.stat(DiskService.path_for(key))
      callable.()
      after_file = File.stat(DiskService.path_for(key))

      assert ^before_file = after_file
    end

    defp assert_file_created(key, callable) do
      refute File.exists?(DiskService.path_for(key))
      callable.()
      assert File.exists?(DiskService.path_for(key))
    end

    defp remove_file_by_key(key) do
      File.rm(DiskService.path_for(key))
    end
  end
end
