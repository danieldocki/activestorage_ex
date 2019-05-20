defmodule ActivestorageExTest.ServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx.Service
  alias ActivestorageEx.Service

  describe "Service.content_disposition_with/3" do
    test "Returns inline disposition if specified" do
      disposition = Service.content_disposition_with("inline", "")

      assert String.starts_with?(disposition, "inline")
    end

    test "Returns attachment disposition if specified" do
      disposition = Service.content_disposition_with("attachment", "")

      assert String.starts_with?(disposition, "attachment")
    end

    test "Returns inline disposition if specified disposition is invalid (close match)" do
      disposition = Service.content_disposition_with("attachments", "")

      assert String.starts_with?(disposition, "inline")
    end

    test "Returns inline disposition if specified disposition is invalid" do
      disposition = Service.content_disposition_with("something bad", "")

      assert String.starts_with?(disposition, "inline")
    end

    test "Returns a full, valid Content-Disposition string" do
      disposition = Service.content_disposition_with("inline", "test.txt")

      assert "inline; filename=\"test.txt\"" == disposition
    end

    # NOTE to self. Mocking/stubbing is not idiomatic Elixir (according to my boy Jose).
    # Instead, I'm going to try a basic test here to ensure the function is being called
    # in any capacity.  The function itself will be tested in more depth below
    test "Filenames are sanitized" do
      disposition = Service.content_disposition_with("", " some/\\<>thing: ")

      assert String.contains?(disposition, "\"something\"")
    end
  end

  describe "Service.sanitize/2" do
    test "Strings are normalized against outside whitespace" do
      Enum.each(["s", " s", "s ", " s ", "\n s    \n"], fn name ->
        cleaned_name = Service.sanitize(name)

        assert String.contains?(cleaned_name, "s")
      end)
    end

    test "Strings are normalized against internal whitespace" do
      Enum.each(["x x", "x  x", "x   x", "x  |  x", "x\tx", "x\r\nx"], fn name ->
        cleaned_name = Service.sanitize(name)

        assert String.contains?(cleaned_name, "x x")
      end)
    end

    test "Strings are truncated to 255 characters" do
      long_string = String.duplicate("Z", 400)

      assert 255 == String.length(Service.sanitize(long_string))
    end

    test "Strings are truncated to 255 characters, less the padding" do
      long_string = String.duplicate("Z", 400)

      assert 245 == String.length(Service.sanitize(long_string, padding: 10))
    end

    test "Sanitization ignores roman characters" do
      assert "åbçdëf" == Service.sanitize("åbçdëf")
    end

    test "Sanitization ignores valid, extended characters" do
      assert "笊, ざる.txt" == Service.sanitize("笊, ざる.txt")
    end

    test "Sanitization removes all filename-unsafe characters in isolation" do
      Enum.each(["<", ">", "|", "/", "\\", "*", "?", ":"], fn char ->
        assert "a" == Service.sanitize("a#{char}")
        assert "a" == Service.sanitize("#{char}a")
        assert "aa" == Service.sanitize("a#{char}a")
      end)
    end

    test "Sanitization removes filename-unsafe characters in combination" do
      assert "whatēverwëirdînput" == Service.sanitize(" what\\ēver//wëird:înput:")
    end

    test "A fallback is provided if no input is given" do
      assert "file" == Service.sanitize("")
    end

    test "A fallback is provided if no valid input is given" do
      assert "file" == Service.sanitize("\\:?")
    end

    test "Custom fallback can be specified" do
      assert "custom_name" == Service.sanitize("", filename_fallback: "custom_name")
    end

    test "Sanitization removes all windows-unsafe strings" do
      # This is only a subset of windows-unsafe strings,
      # but it covers a few potential obfuscation tactics
      Enum.each(["CON", "lpt1", "com4", "aux ", "LpT\x122"], fn char ->
        assert "file" == Service.sanitize(char)
      end)
    end

    test "Filenames that begin with a dot are prepended with the default" do
      assert "file.txt" == Service.sanitize(".txt")
    end

    test "Filenames that begin with a dot and invalid chars are prepended" do
      assert "file.txt" == Service.sanitize(">.txt")
    end

    test "Filenames that begin with two dots are prepended with dots preserved" do
      assert "file..txt" == Service.sanitize("..txt")
    end
  end
end
