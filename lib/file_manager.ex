defmodule FileManager do
  @moduledoc """
  The FileManager application implements a simple, in-memory file system.
  Callers access the file system after initiating a session that maintains state
  such as the current working directory and permissions.
  """

  alias FileManager.Session
  alias FileManager.Storage

  defdelegate open_session, to: Session, as: :open
  defdelegate current_working_directory(session), to: Session

  def list_directory(session, path) do
    with {:ok, cwd} <- current_working_directory(session) do
      path
      |> Path.expand(cwd)
      |> Storage.list_directory()
    end
  end

  def make_directory(session, path) do
    with {:ok, cwd} <- current_working_directory(session) do
      path
      |> Path.expand(cwd)
      |> Storage.make_directory()
    end
  end
end
