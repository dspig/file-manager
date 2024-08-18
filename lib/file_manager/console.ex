defmodule FileManager.Console do
  defmacro __using__(_) do
    quote do
      import FileManager.Session
    end
  end
end
