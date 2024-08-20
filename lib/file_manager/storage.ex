defmodule FileManager.Storage do
  @moduledoc """
  Module responsible for managing the in-memory files and directories.
  """
  use GenServer

  alias FileManager.Storage.Directory
  alias FileManager.Storage.File

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_), do: {:ok, %Directory{files: %{}}}

  @impl GenServer
  def handle_call({:exists?, type, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         :ok <- check_path_parts(paths, type, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

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
         {:ok, root} <- do_delete_directory(paths, root) do
      {:reply, :ok, root}
    else
      {:error, _} = error -> {:reply, error, root}
    end
  end

  def handle_call({:create_file, file_name}, _from, root) do
    with {:ok, paths} <- split_absolute_path(file_name),
         {:ok, root} <- do_create_file(paths, root) do
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
       when is_map_key(files, directory),
       do: get_directory(paths, Map.get(files, directory))

  defp get_directory([_ | _], _directory), do: {:error, :invalid_path}
  defp get_directory(_paths, _directory), do: {:error, :invalid_path}

  defp split_absolute_path("/" <> path), do: {:ok, Path.split(path)}
  defp split_absolute_path(_path), do: {:error, :invalid_path}

  defp check_path_parts([], :directory, %Directory{}), do: :ok
  defp check_path_parts([], :file, %File{}), do: :ok

  defp check_path_parts([path | paths], type, %Directory{files: files})
       when is_map_key(files, path),
       do: check_path_parts(paths, type, Map.get(files, path))

  defp check_path_parts(_paths, _type, _directory), do: {:error, :invalid_path}

  defp do_make_directory([directory], %Directory{files: files} = parent)
       when not is_map_key(files, directory),
       do: {:ok, %{parent | files: Map.put(files, directory, %Directory{})}}

  defp do_make_directory([directory], %Directory{files: files})
       when is_map_key(files, directory),
       do: {:error, :already_exists}

  defp do_make_directory([directory | directories], %Directory{files: files} = parent)
       when is_map_key(files, directory) do
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

  defp do_delete_directory([directory], %Directory{files: files} = parent)
       when is_map_key(files, directory) do
    if match?(%Directory{}, Map.get(files, directory)) do
      {:ok, %{parent | files: Map.delete(parent.files, directory)}}
    else
      {:error, :invalid_path}
    end
  end

  defp do_delete_directory([directory | directories], %Directory{files: files} = parent)
       when is_map_key(files, directory) do
    with {:ok, child} <- do_delete_directory(directories, Map.get(files, directory)) do
      {:ok, %{parent | files: Map.put(files, directory, child)}}
    end
  end

  defp do_delete_directory(_directories, _parent), do: {:error, :invalid_path}

  defp do_create_file([file_name], %Directory{files: files} = parent)
       when not is_map_key(files, file_name),
       do: {:ok, %{parent | files: Map.put(files, file_name, %File{})}}

  defp do_create_file([file_name], %Directory{files: files})
       when is_map_key(files, file_name),
       do: {:error, :already_exists}

  defp do_create_file([directory | paths], %Directory{files: files} = parent) do
    with {:ok, child} <- do_create_file(paths, Map.get(files, directory, %Directory{})) do
      {:ok, %{parent | files: Map.put(files, directory, child)}}
    end
  end

  defp do_create_file(_directories, _parent), do: {:error, :invalid_path}

  @doc """
  Checks if a path exists or not.

  ## Examples

      iex> Storage.exists?("/", :directory)
      :ok
      iex> Storage.exists?("/foo", :directory)
      {:error, :invalid_path}
  """
  def exists?(path, type) when type in [:directory, :file],
    do: GenServer.call(__MODULE__, {:exists?, type, path})

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
  def create_file(file_name), do: GenServer.call(__MODULE__, {:create_file, file_name})

  @doc """
  Resets the storage to an empty state.

  ## Examples

      iex> Storage.reset()
      :ok
  """
  def reset(), do: GenServer.cast(__MODULE__, {:reset})
end
