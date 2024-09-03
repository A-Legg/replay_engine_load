defmodule ReplayEngineLoad.SocketClient do
  use WebSockex

  # 1 second
  @initial_reconnect_delay 1_000
  # 1 minute
  @max_reconnect_delay 60_000

  def start_link(url, state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  def handle_frame({_, msg}, state) do
    send(state.listener_pid, {:socket_msg, msg})
    {:ok, state}
  end

  def send_message(pid, msg) do
    payload = Jason.encode!(msg)
    WebSockex.send_frame(pid, {:text, payload})
  end

  def handle_disconnect(_status, state) do
    IO.puts("Disconnected from WebSocket. Attempting to reconnect...")
    current_delay = Map.get(state, :reconnect_delay, @initial_reconnect_delay)
    Process.send_after(self(), :reconnect, current_delay)

    new_state = Map.put(state, :reconnect_delay, min(current_delay * 2, @max_reconnect_delay))
    {:ok, new_state}
  end

  def handle_info(:reconnect, state) do
    case start_link(state.websocket_url, %{
           listener_pid: state.listener_pid,
           reconnect_delay: @initial_reconnect_delay
         }) do
      {:ok, _pid} ->
        IO.puts("Reconnected successfully.")
        # Delay sending the next message to ensure connection is stable
        Process.send_after(state.listener_pid, :new_matchup, 1_000)
        {:ok, %{state | reconnect_delay: @initial_reconnect_delay}}

      {:error, _reason} ->
        IO.puts("Reconnection failed, will retry...")
        Process.send_after(self(), :reconnect, state.reconnect_delay)
        {:ok, state}
    end
  end

  def terminate(close_reason, state) do
    IO.warn("WebSocket connection closed: #{inspect(close_reason)}")
    {:ok, state}
  end
end
