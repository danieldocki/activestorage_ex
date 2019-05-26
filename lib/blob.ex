defmodule ActivestorageEx.Blob do
  @enforce_keys [:key, :content_type, :filename]
  defstruct key: nil,
            content_type: nil,
            filename: nil
end
