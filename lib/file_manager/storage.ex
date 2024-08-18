defmodule FileManager.Storage do
  @moduledoc """
  Module responsible for managing the in-memory files and directories.
  """
  use GenServer

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_), do: {:ok, %__MODULE__.Directory{name: "/", files: %{}}}

  @impl GenServer
  def handle_call({:exists?, path}, _from, root) do
    path
    |> Path.split()
    |> case do
      ["/" | paths] -> {:reply, check_path_parts(paths, root), root}
      _ -> {:reply, {:error, :invalid_path}, root}
    end
  end

  defp check_path_parts([], _), do: :ok

  defp check_path_parts([path | paths], %__MODULE__.Directory{} = directory)
       when is_map_key(directory, path),
       do: check_path_parts(paths, Map.get(directory.files, path))

  defp check_path_parts([_ | _], _directory), do: {:error, :invalid_path}

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
end
