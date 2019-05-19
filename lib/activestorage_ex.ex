defmodule ActivestorageEx do
  def env(name) do
    Application.get_env(:activestorage_ex, name)
  end
end
