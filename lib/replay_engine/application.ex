defmodule ReplayEngineLoad.Application do
  use Application

  def start(_type, _args) do
    children = [
      {ReplayEngineLoad.DynamicSupervisor, []},
      {ReplayEngineLoad.LoadTest, []},
      {Registry, keys: :unique, name: ReplayEngineLoad.Registry}
    ]

    opts = [strategy: :one_for_one, name: ReplayEngineLoad.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
