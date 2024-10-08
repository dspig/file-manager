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
    with {:ok, path} <- expand_path(session, path) do
      Storage.list_directory(path)
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

  def make_directory(_session, ""), do: {:error, :invalid_path}

  def make_directory(session, path) do
    with {:ok, path} <- expand_path(session, path) do
      Storage.make_directory(path)
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
  files. An error is returned if the target directory is a parent of the current
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

  @doc """
  Create a file with the given path. Intermediate directories are created, if
  necessary. If the file already exists, an error is returned.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.create_file(session, "/foo/bar/baz")
    :ok
  """
  def create_file(_session, "" = _path), do: {:error, :invalid_path}

  def create_file(session, path) do
    with {:ok, path} <- expand_path(session, path) do
      Storage.create_file(path)
    end
  end

  @doc """
  Write contents to a file with the given path.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.create_file(session, "/foo/bar/baz")
    iex> FileManager.write_file(session, "/foo/bar/baz", "Hello, world!")
    :ok
  """
  def write_file(_session, "" = _filename, _contents), do: {:error, :invalid_path}

  def write_file(session, path, contents) do
    with {:ok, path} <- expand_path(session, path) do
      Storage.write_file(path, contents)
    end
  end

  @doc """
  Read the contents of a file with the given path.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.create_file(session, "/foo/bar/baz")
    iex> FileManager.write_file(session, "/foo/bar/baz", "Hello, world!")
    iex> FileManager.read_file(session, "/foo/bar/baz")
    {:ok, "Hello, world!"}
  """
  def read_file(_session, "" = _path), do: {:error, :invalid_path}

  def read_file(session, path) do
    with {:ok, path} <- expand_path(session, path) do
      Storage.read_file(path)
    end
  end

  @doc """
  Move a file or directory, creating intermediate directories as needed.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.create_file(session, "/foo/bar")
    iex> FileManager.move(session, "/foo/bar", "/biz/baz")
    :ok
    iex> FileManager.list_directory(session, "/biz")
    {:ok, ["baz"]}
  """
  def move(_session, "" = _from_path, _to_path), do: {:error, :invalid_path}
  def move(_session, _from_path, "" = _to_path), do: {:error, :invalid_path}

  def move(session, from_path, to_path) do
    with {:ok, from_path} <- expand_path(session, from_path),
         {:ok, to_path} <- expand_path(session, to_path) do
      Storage.move(from_path, to_path)
    end
  end

  @doc """
  Fine a file or directory by name, optionally from a target path.

  ## Examples
    iex> {:ok, session} = FileManager.open_session()
    iex> FileManager.create_file(session, "/foo/bar")
    iex> FileManager.find(session, "bar")
    {:ok, ["/foo/bar"]}
    iex> FileManager.find(session, "bar", "/foo")
    {:ok, ["bar"]}
  """
  def find(session, filename, path \\ ".") do
    with {:ok, path} <- expand_path(session, path) do
      Storage.find(path, filename)
    end
  end

  defp expand_path(session, path) do
    with {:ok, cwd} <- current_working_directory(session) do
      {:ok, Path.expand(path, cwd)}
    end
  end
end
