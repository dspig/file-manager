defmodule MsFs.Session do
  @moduledoc """
  This modules is responsible for managing file system sessions. To interact
  with the file system, callers need to first open a session. The session
  maintains the caller's current working directory.
  """
  use GenServer

  defstruct current_working_directory: "/"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

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
    |> Map.get(id)
    |> case do
      nil -> {:reply, {:error, :invalid_session}, sessions}
      session -> {:reply, {:ok, session.current_working_directory}, sessions}
    end
  end

  @doc """
  Open a file system session.

  ## Examples
    iex> {:ok, session} = Session.open()
    {:ok, session}
  """
  def open do
    GenServer.call(__MODULE__, {:new_session})
  end

  @doc """
  Close a file system session.

  ## Examples
    iex> {:ok, session} = Session.open()
    {:ok, session}
    iex> Session.close(session)
    :ok


  """
  def close(session) do
    GenServer.call(__MODULE__, {:close_session, session})
  end

  @doc """
  Get the current working directory for a session.

  ## Examples
    iex> {:ok, session} = Session.open()
    {:ok, session}
    iex> Session.current_working_directory(session)
    {:ok, "/"}

  """
  def current_working_directory(session) do
    GenServer.call(__MODULE__, {:current_working_directory, session})
  end
end
