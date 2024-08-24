defmodule FileManager.Storage do
  @moduledoc """
  Module responsible for managing the in-memory files and directories.
  """
  use GenServer

  alias FileManager.Storage.Directory
  alias FileManager.Storage.File

  defguard is_child(files, file) when is_map_key(files, file)

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_), do: {:ok, %Directory{files: %{}}}

  @impl GenServer
  def handle_call({:make_directory, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, root} <- do_make_directory(paths, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:list_directory, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, directory} <- get_directory(paths, root) do
      {:reply, {:ok, Map.keys(directory.files)}, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:delete_directory, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, _target, root} <- do_delete_directory(paths, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:create_file, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, root} <- do_create_file(paths, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:write_file, path, contents}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, root} <- do_write_file(paths, root, contents) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:read_file, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         {:ok, contents} <- do_read_file(paths, root) do
      {:reply, {:ok, contents}, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:move, from, to}, _from, root) do
    with {:ok, from} <- split_absolute_path(from),
         {:ok, target, root} <- do_delete(from, root),
         {:ok, to} <- split_absolute_path(to),
         {:ok, root} <- do_move(to, target, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  @impl GenServer
  def handle_cast({:reset}, _root) do
    {:noreply, %Directory{files: %{}}}
  end

  defp get_directory([], %Directory{} = directory), do: {:ok, directory}

  defp get_directory([directory | paths], %Directory{files: files})
       when is_child(files, directory),
       do: get_directory(paths, Map.get(files, directory))

  defp get_directory([_ | _], _directory), do: {:error, :invalid_path}
  defp get_directory(_paths, _directory), do: {:error, :invalid_path}

  defp split_absolute_path("/" <> path), do: {:ok, Path.split(path)}
  defp split_absolute_path(_path), do: {:error, :invalid_path}

  defp do_make_directory([directory], %Directory{files: files} = parent)
       when not is_child(files, directory),
       do: {:ok, %{parent | files: Map.put(files, directory, %Directory{})}}

  defp do_make_directory([directory], %Directory{files: files})
       when is_child(files, directory),
       do: {:error, :already_exists}

  defp do_make_directory([directory | directories], %Directory{files: files} = parent)
       when is_child(files, directory) do
    with {:ok, child} <- do_make_directory(directories, Map.get(files, directory)) do
      {:ok, %{parent | files: Map.put(files, directory, child)}}
    end
  end

  defp do_make_directory([directory | directories], %Directory{} = parent) do
    with {:ok, child} <- do_make_directory(directories, %Directory{}) do
      {:ok, %{parent | files: Map.put(parent.files, directory, child)}}
    end
  end

  defp do_make_directory(_directories, _parent), do: {:error, :invalid_path}

  defp do_delete_directory(directories, %Directory{} = parent) do
    directories
    |> do_delete(parent)
    |> case do
      {:ok, %Directory{} = target, root} -> {:ok, target, root}
      _ -> {:error, :invalid_path}
    end
  end

  defp do_delete([target], %Directory{files: files} = parent) do
    files
    |> Map.pop(target)
    |> case do
      {nil, _} -> {:error, :invalid_path}
      {file, files} -> {:ok, file, %{parent | files: files}}
    end
  end

  defp do_delete([directory | paths], %Directory{files: files} = parent) do
    with {:ok, target, child} <- do_delete(paths, Map.get(files, directory)) do
      {:ok, target, %{parent | files: Map.put(files, directory, child)}}
    end
  end

  defp do_delete(_directories, _parent), do: {:error, :invalid_path}

  defp do_move([path], target, %Directory{files: files} = parent)
       when not is_child(files, path),
       do: {:ok, %{parent | files: Map.put(files, path, target)}}

  defp do_move([path | paths], target, %Directory{files: files} = parent) do
    with {:ok, child} <- do_move(paths, target, Map.get(files, path, %Directory{})) do
      {:ok, %{parent | files: Map.put(files, path, child)}}
    end
  end

  defp do_move(_paths, _target, _parent), do: {:error, :invalid_path}

  defp do_create_file([filename], %Directory{files: files} = parent)
       when not is_child(files, filename),
       do: {:ok, %{parent | files: Map.put(files, filename, %File{})}}

  defp do_create_file([filename], %Directory{files: files})
       when is_child(files, filename),
       do: {:error, :already_exists}

  defp do_create_file([directory | paths], %Directory{files: files} = parent) do
    with {:ok, child} <- do_create_file(paths, Map.get(files, directory, %Directory{})) do
      {:ok, %{parent | files: Map.put(files, directory, child)}}
    end
  end

  defp do_create_file(_directories, _parent), do: {:error, :invalid_path}

  defp do_write_file([], %File{} = file, contents),
    do: {:ok, Map.update(file, :contents, contents, &(&1 <> contents))}

  defp do_write_file([path | paths], %Directory{files: files} = parent, contents)
       when is_child(files, path) do
    with {:ok, child} <- do_write_file(paths, Map.get(files, path), contents) do
      {:ok, %{parent | files: Map.put(files, path, child)}}
    end
  end

  defp do_write_file(_paths, _parent, _contents), do: {:error, :invalid_path}

  defp do_read_file([], %File{contents: contents}), do: {:ok, contents}

  defp do_read_file([directory | paths], %Directory{files: files})
       when is_child(files, directory),
       do: do_read_file(paths, Map.get(files, directory))

  defp do_read_file(_paths, _parent), do: {:error, :invalid_path}

  @doc """
  Creates a directory at the given path.
  """
  def make_directory(path), do: GenServer.call(__MODULE__, {:make_directory, path})

  @doc """
  Lists the contents of a directory.
  """
  def list_directory(path), do: GenServer.call(__MODULE__, {:list_directory, path})

  @doc """
  Deletes a directory at the given path.
  """
  def delete_directory(path), do: GenServer.call(__MODULE__, {:delete_directory, path})

  @doc """
  Creates a file at the given path.
  """
  def create_file(path), do: GenServer.call(__MODULE__, {:create_file, path})

  @doc """
  Writes contents to a file at the given path.
  """
  def write_file(path, contents),
    do: GenServer.call(__MODULE__, {:write_file, path, contents})

  @doc """
  Reads the contents of a file at the given path.
  """
  def read_file(path),
    do: GenServer.call(__MODULE__, {:read_file, path})

  @doc """
  Moves a file or directory from one path to another.
  """
  def move(from, to), do: GenServer.call(__MODULE__, {:move, from, to})

  @doc """
  Resets the storage to an empty state.

  ## Examples

      iex> Storage.reset()
      :ok
  """
  def reset(), do: GenServer.cast(__MODULE__, {:reset})
end
