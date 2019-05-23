defmodule ActivestorageExTest.VariationTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variation
  alias ActivestorageEx.Variation

  @image_filepath "test/files/image.jpg"

  describe "ActivestorageEx.transform/2" do
    test "A %Mogrify.Image{} is returned" do
      %struct_name{} = Variation.transform(%{}, @image_filepath)

      assert Mogrify.Image == struct_name
    end

    test "A single operation can be performed" do
      image = Variation.transform(%{resize: "100x100"}, @image_filepath)

      assert [resize: "100x100"] = image.operations
    end

    test "Multiple operations can be performed" do
      image = Variation.transform(%{extent: "100x100", gravity: "Center"}, @image_filepath)

      assert [extent: "100x100", gravity: "Center"] = image.operations
    end
  end
end
