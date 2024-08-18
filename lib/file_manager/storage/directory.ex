defmodule FileManager.Storage.Directory do
  @enforce_keys [:name]
  defstruct [:name, files: %{}]
end
