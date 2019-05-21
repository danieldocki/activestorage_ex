defmodule ActivestorageExTest do
  use ExUnit.Case
  doctest ActivestorageEx

  @rakefile_path "external/activestorage_ex_rails/Rakefile"

  def get_local_upload_key() do
    {key, _exit_code} = System.cmd("rake", ["-f", @rakefile_path, "get_local_upload_key"])

    key
  end

  describe "ActivestorageEx.env/1" do
    test "It reads environment variables" do
      env_value = ActivestorageEx.env(:root_path)
      application_get_value = Application.get_env(:activestorage_ex, :root_path)

      assert application_get_value == env_value
    end
  end
end
