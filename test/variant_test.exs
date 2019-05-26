defmodule ActivestorageExTest.VariantTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variant
  alias ActivestorageEx.Variant
  alias ActivestorageEx.Blob

  @local_key TestHelper.get_local_upload_key()

  @mock_blob %Blob{
    key: @local_key,
    filename: "foo.png",
    content_type: "image/png"
  }

  describe "Variant.key/2" do
    test "A variant key includes the root blob's key" do
      variant_key = Variant.key(@mock_blob, [])

      assert String.contains?(variant_key, "foo")
    end

    test "A variant key includes a unique hash of the transformations" do
      variant_key_1 = Variant.key(@mock_blob, [%{resize: "1x1"}])
      variant_key_2 = Variant.key(@mock_blob, [%{extent: "1x1"}])

      refute variant_key_1 == variant_key_2
    end
  end

  describe "Variant.process/2" do
    test "oh god please help" do
      d =
        Variant.processed(
          @mock_blob,
          [
            %{resize: "100x100^"},
            %{extent: "100x100"}
          ]
        )
        |> Variant.service_url()

      # |> String.split("/")
      # |> Enum.at(3)
      # |> ActivestorageEx.verify_message()

      IO.puts(inspect(d))
    end
  end
end
