ExUnit.start()

defmodule TestHelper do
  @rakefile_path "external/activestorage_ex_rails/Rakefile"

  def get_local_upload_key() do
    {key, _exit_code} = System.cmd("rake", ["-f", @rakefile_path, "get_local_upload_key"])

    key
  end
end
