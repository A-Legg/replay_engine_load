defmodule ReplayEngineLoad.ReplayEngineClient do
  use GenServer
  alias ReplayEngineLoad.{ClientPayloads, SocketClient}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  def init(args) do
    state =
      %{
        client_pid: nil,
        replayed_on: nil,
        count: 0,
        errors: [],
        user_id: UUID.uuid4(),
        test_duration: args.test_duration,
        start_time: System.monotonic_time(:second)
      }

    {:ok, state, {:continue, :start_client}}
  end

  def handle_continue(:start_client, state) do
    {:noreply, start_client(state)}
  end

  def handle_info(:new_matchup, state) do
    if Process.alive?(state.client_pid) do
      new_matchup = ClientPayloads.new_matchup("mlb", "plate_appearance")
      SocketClient.send_message(state.client_pid, new_matchup)
    else
      IO.warn("Attempted to send a message on a closed WebSocket.")
      Process.send_after(self(), :reconnect, 1000)
    end

    Process.send_after(self(), :new_matchup, 10_000)
    {:noreply, %{state | count: state.count + 1}}
  end

  def handle_info(:transition_matchup, state) do
    if Process.alive?(state.client_pid) do
      transition_matchup = ClientPayloads.transition_matchup()
      SocketClient.send_message(state.client_pid, transition_matchup)
    else
      IO.warn("Attempted to send a message on a closed WebSocket.")
      Process.send_after(self(), :reconnect, 1000)
    end

    {:noreply, state}
  end

  def handle_info({:socket_msg, msg}, state) do
    msg = Jason.decode!(msg, keys: :atoms)
    state = handle_socket_message(msg, state)
    {:noreply, state}
  end

  def handle_info(:stop_test, state) do
    {:stop, :normal, state}
  end

  def handle_info(:reconnect, state) do
    IO.puts("Reconnecting client...")
    {:noreply, start_client(state)}
  end

  defp start_client(state) do
    config = ReplayEngineLoad.config()

    case SocketClient.start_link(config.websocket_url, %{
           listener_pid: self(),
           websocket_url: config.websocket_url
         }) do
      {:ok, client_pid} ->
        Process.sleep(Enum.random(0..20_000))
        join_payload = ClientPayloads.join_topic("matchups", state.user_id)
        SocketClient.send_message(client_pid, join_payload)

        new_matchup = ClientPayloads.new_matchup("mlb", "plate_appearance")
        SocketClient.send_message(client_pid, new_matchup)

        Process.send_after(self(), :stop_test, state.test_duration)
        Process.send_after(self(), :new_matchup, 10_000)
        %{state | client_pid: client_pid, count: 1}

      {:error, _} ->
        Process.sleep(5000)
        start_client(state)
    end
  end

  defp handle_socket_message(msg, state) do
    case msg do
      %{
        event: "phx_reply",
        payload: %{response: %{replayed_on: replayed_on, market: %{id: market_id}}}
      } ->
        Process.sleep(1000)
        send_bet(market_id, state.user_id, replayed_on)
        %{state | replayed_on: replayed_on}

      %{event: "new_market", payload: %{id: market_id}} ->
        Process.sleep(1000)
        send_bet(market_id, state.user_id, state.replayed_on)
        state

      %{event: "market_result"} ->
        Process.sleep(1000)
        send(self(), :transition_matchup)
        state

      %{event: "matchup_complete"} ->
        Process.sleep(1000)
        send(self(), :new_matchup)
        state

      %{event: "phx_close"} ->
        Process.sleep(1000)
        send(self(), :new_matchup)
        state

      %{status: "error", response: "not_found"} ->
        Process.sleep(1000)
        send(self(), :new_matchup)
        state

      _ ->
        state
    end
  end

  defp send_bet(market_id, user_id, replayed_on) do
    config = ReplayEngineLoad.config()

    body = %{
      market_id: market_id,
      selection_label: "strike_or_foul",
      user_id: user_id,
      replayed_on: replayed_on
    }

    case Req.post(config.bet_url, json: body) do
      {:ok, _response} ->
        :ok
      {:error, error} ->
        IO.puts("Error placing bet: #{inspect(error)}", market_id: market_id)
    end
  end
end
