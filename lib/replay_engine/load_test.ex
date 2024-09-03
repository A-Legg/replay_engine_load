defmodule ReplayEngineLoad.LoadTest do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :start_test, 0)
    {:ok, %{}}
  end

  def handle_info(:start_test, state) do
    config = ReplayEngineLoad.config() |> IO.inspect(label: :configz)

    IO.puts(
      "Starting load test with #{config.num_users} users over #{config.test_duration_seconds} seconds."
    )

    Enum.each(1..config.num_users, fn i ->
      ReplayEngineLoad.DynamicSupervisor.start_child(%{
        test_duration: config.test_duration_seconds * 1000,
        name: {:via, Registry, {ReplayEngineLoad.Registry, {:replay_engine_client, i}}}
      })
    end)

    Process.send_after(self(), :stop_test, config.test_duration_seconds * 1000)
    {:noreply, state}
  end

  def handle_info(:stop_test, state) do
    IO.puts("Load test completed.")
    System.stop(0)
    {:noreply, state}
  end
end
