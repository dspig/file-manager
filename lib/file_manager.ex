defmodule FileManager do
  @moduledoc """
  The FileManager application implements a simple, in-memory file system.
  Callers access the file system after initiating a session that maintains state
  such as the current working directory and permissions.
  """

  defdelegate open_session, to: __MODULE__.Session, as: :open
  defdelegate current_working_directory(session), to: __MODULE__.Session
end
