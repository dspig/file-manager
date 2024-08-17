defmodule MsFs.Console do
  defmacro __using__(_) do
    quote do
      import MsFs.Session
    end
  end
end
