defmodule ActivestorageExTest.VariantTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variant
  alias ActivestorageEx.Variant

  @local_key TestHelper.get_local_upload_key()

  describe "Variant.key/2" do
    test "A variant key includes the root blob's key" do
      variant_key = Variant.key(%{key: "foo"}, [])

      assert String.contains?(variant_key, "foo")
    end

    test "A variant key includes a unique hash of the transformations" do
      variant_key_1 = Variant.key(%{key: "foo"}, [%{resize: "1x1"}])
      variant_key_2 = Variant.key(%{key: "foo"}, [%{extent: "1x1"}])

      refute variant_key_1 == variant_key_2
    end
  end

  describe "Variant.process/2" do
    test "oh god please help" do
      d =
        Variant.processed(
          %{
            key: @local_key,
            filename: "test_filename.asd",
            content_type: "image/what"
          },
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
