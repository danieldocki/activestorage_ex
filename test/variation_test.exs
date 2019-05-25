defmodule ActivestorageExTest.VariationTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variation
  alias ActivestorageEx.Variation

  @image_filepath "test/files/image.jpg"

  describe "ActivestorageEx.encode/1" do
    test "A list of transformations is encoded into a JWT" do
      token = Variation.encode([])

      assert {:ok, _message} = Base.url_decode64(token)
    end
  end

  describe "ActivestorageEx.decode/1" do
    test "A list of transformations is decoded from a JWT" do
      token = Variation.encode([%{foo: "bar"}])
      transformations = Variation.decode(token)

      assert [%{"foo" => "bar"}] = transformations
    end
  end

  describe "ActivestorageEx.transform/2" do
    test "A %Mogrify.Image{} is returned" do
      %struct_name{} = Variation.transform([], @image_filepath)

      assert Mogrify.Image == struct_name
    end

    test "A single operation can be performed" do
      image = Variation.transform([%{resize: "100x100"}], @image_filepath)

      assert [resize: "100x100"] = image.operations
    end

    test "Multiple operations can be performed" do
      image =
        Variation.transform(
          [
            %{extent: "100x100"},
            %{gravity: "Center"}
          ],
          @image_filepath
        )

      assert [extent: "100x100", gravity: "Center"] = image.operations
    end

    test "Multiple operations have their order preserved" do
      image =
        Variation.transform(
          [
            %{gravity: "Center"},
            %{extent: "100x100"}
          ],
          @image_filepath
        )

      assert [gravity: "Center", extent: "100x100"] = image.operations
    end
  end
end
