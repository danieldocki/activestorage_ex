defmodule ActivestorageExTest.VariantTest do
  use ExUnit.Case
  doctest ActivestorageEx.Variant
  alias ActivestorageEx.Variant

  describe "ActivestorageEx.Variant.key/2" do
    test "A variant key inluces the root blob's key" do
      variant_key = Variant.key(%{key: "foo"}, %{})

      assert String.contains?(variant_key, "foo")
    end
  end
end
