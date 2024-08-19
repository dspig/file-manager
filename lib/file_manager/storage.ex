defmodule FileManager.Storage do
  @moduledoc """
  Module responsible for managing the in-memory files and directories.
  """
  use GenServer

  alias FileManager.Storage.Directory

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_), do: {:ok, %Directory{files: %{}}}

  @impl GenServer
  def handle_call({:exists?, path}, _from, root) do
    with {:ok, paths} <- split_absolute_path(path),
         :ok <- check_path_parts(paths, root) do
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

  @impl GenServer
  def handle_cast({:reset}, _root) do
    {:noreply, %Directory{files: %{}}}
  end

  defp split_absolute_path("/" <> path), do: {:ok, Path.split(path)}
  defp split_absolute_path(_path), do: {:error, :invalid_path}

  defp check_path_parts([], _), do: :ok

  defp check_path_parts([path | paths], %Directory{files: files})
       when is_map_key(files, path),
       do: check_path_parts(paths, Map.get(files, path))

  defp check_path_parts([_ | _], _directory), do: {:error, :invalid_path}

  defp do_make_directory([directory], %Directory{files: files} = parent)
       when not is_map_key(files, directory),
       do: {:ok, %{parent | files: Map.put(parent.files, directory, %Directory{})}}

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

  @doc """
  Checks if a path exists or not.

  ## Examples

      iex> Storage.exists?("/")
      :ok
      iex> Storage.exists?("/foo")
      {:error, :invalid_path}
  """
  def exists?(path) do
    GenServer.call(__MODULE__, {:exists?, path})
  end

  @doc """
  Creates a directory at the given path.

  ## Examples

      iex> Storage.make_directory("/foo")
      :ok
      iex> Storage.make_directory("/foo/bar/baz")
      :ok
      iex> Storage.make_directory("/foo")
      {:error, :already_exists}
  """
  def make_directory(path) do
    GenServer.call(__MODULE__, {:make_directory, path})
  end

  @doc """
  Resets the storage to an empty state.

  ## Examples

      iex> Storage.reset()
      :ok
  """
  def reset() do
    GenServer.cast(__MODULE__, {:reset})
  end
end
