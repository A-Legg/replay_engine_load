defmodule ReplayEngineLoad do
  @moduledoc """
  Documentation for `ReplayEngineLoad`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ReplayEngineLoad.hello()
      :world

  """
  def config do
    %{
      websocket_url: "wss://replay-engine.staging.simplebet.io/replay-engine/socket/websocket",
      bet_url: "https://replay-engine-customer.staging.simplebet.io/replay-engine-customer/bets",
      num_users: 100,
      test_duration_seconds: 60 * 10
    }
  end
end
