defmodule FileManager.Session do
  @moduledoc """
  This modules is responsible for managing file system sessions. To interact
  with the file system, callers need to first open a session. The session
  maintains the caller's current working directory.
  """
  use GenServer

  alias FileManager.Storage

  defstruct current_working_directory: "/"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_), do: {:ok, %{}}

  @impl GenServer
  def handle_call({:new_session}, _from, sessions) do
    id = make_ref()
    {:reply, {:ok, id}, Map.put_new(sessions, id, %__MODULE__{})}
  end

  def handle_call({:close_session, id}, _from, sessions) do
    sessions
    |> Map.pop(id)
    |> case do
      {nil, sessions} -> {:reply, {:error, :invalid_session}, sessions}
      {_id, sessions} -> {:reply, :ok, sessions}
    end
  end

  def handle_call({:current_working_directory, id}, _from, sessions) do
    sessions
    |> get_session(id)
    |> case do
      {:ok, %__MODULE__{} = session} ->
        {:reply, {:ok, session.current_working_directory}, sessions}

      {:error, _} = result ->
        {:reply, result, sessions}
    end
  end

  def handle_call({:change_directory, id, path}, _from, sessions) do
    with {:ok, session} <- get_session(sessions, id),
         cwd = build_cwd(session.current_working_directory, path),
         :ok <- Storage.exists?(cwd) do
      new_session = %{session | current_working_directory: cwd}

      {:reply, {:ok, new_session.current_working_directory}, Map.put(sessions, id, new_session)}
    else
      {:error, _} = error -> {:reply, error, sessions}
    end
  end

  defp get_session(sessions, id) do
    sessions
    |> Map.get(id)
    |> case do
      nil -> {:error, :invalid_session}
      %__MODULE{} = session -> {:ok, session}
    end
  end

  defp build_cwd(_current_cwd, "/" <> _ = new_cwd), do: new_cwd

  defp build_cwd(current_cwd, new_cwd) do
    current_cwd
    |> Path.join(new_cwd)
    |> Path.expand()
  end

  @doc """
  Returns a file system session struct that can be used to interact with other
  file manager functions.
  """
  def open do
    GenServer.call(__MODULE__, {:new_session})
  end

  @doc """
  Close a file system session.
  """
  def close(session) do
    GenServer.call(__MODULE__, {:close_session, session})
  end

  @doc """
  Get the session's current working directory
  """
  def current_working_directory(session) do
    GenServer.call(__MODULE__, {:current_working_directory, session})
  end

  @doc """
  Change the session's current working directory
  """
  def change_directory(session, path) do
    GenServer.call(__MODULE__, {:change_directory, session, path})
  end
end
