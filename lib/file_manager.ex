defmodule FileManager do
  @moduledoc """
  The FileManager application implements a simple, in-memory file system.
  Callers access the file system after initiating a session that maintains state
  such as the current working directory and permissions.
  """

  alias FileManager.Session
  alias FileManager.Storage

  @doc """
  Open a file system session.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    {:ok, session}
  """
  defdelegate open_session, to: Session, as: :open

  @doc """
  Close a file system session.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.close_session(session)
    :ok
    iex> FileManager.close_session(session)
    {:error, :invalid_session}
  """
  defdelegate close_session(session), to: Session, as: :close

  @doc """
  Get the session's current working directory

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.current_working_directory(session)
    {:ok, "/"}
  """
  defdelegate current_working_directory(session), to: Session

  def list_directory(session, path \\ ".") do
    with {:ok, cwd} <- current_working_directory(session) do
      path
      |> Path.expand(cwd)
      |> Storage.list_directory()
    end
  end

  @doc """
  Creates a directory with the given path. Relative paths are resolved using the
  current working directory. Intermediate directories are created if they do not
  exist. If a sub-directory already exists as a non-directory, an error is
  returned. If the terminal directory already exists, an error is returned.

  ## Examples

    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.make_directory(session, "/foo/bar/baz")
    :ok
    iex> FileManager.make_directory(session, "/foo")
    {:error, :already_exists}
  """

  def make_directory(session, path) do
    with {:ok, cwd} <- current_working_directory(session) do
      path
      |> Path.expand(cwd)
      |> Storage.make_directory()
    end
  end

  @doc """
  Change the current working directory of the session.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.make_directory(session, "/foo/bar/baz")
    :ok
    iex> FileManager.change_directory(session, "./foo/bar")
    {:ok, "/foo/bar"}
    iex> FileManager.change_directory(session, "./bix")
    {:error, :invalid_path}

  """
  def change_directory(session, path) do
    with {:ok, path} <- expand_path(session, path) do
      Session.change_directory(session, path)
    end
  end

  @doc """
  Delete a directory with the given path, including nested directories and
  files. An error is thrown if the target directory is a parent of the current
  working directory.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.make_directory(session, "/foo/bar/baz")
    :ok
    iex> FileManager.delete_directory(session, "/foo")
    :ok
    iex> FileManager.list_directory(session)
    {:ok, []}
  """
  def delete_directory(session, path) do
    with {:ok, cwd} <- current_working_directory(session),
         {:ok, path} <- expand_path(session, path) do
      if String.starts_with?(cwd, path) do
        {:error, :invalid_path}
      else
        Storage.delete_directory(path)
      end
    end
  end

  defp expand_path(session, path) do
    with {:ok, cwd} <- current_working_directory(session) do
      {:ok, Path.expand(path, cwd)}
    end
  end
end
