defmodule T.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Configuration management
      T.Config,
      # History management
      T.History
    ]

    opts = [strategy: :one_for_one, name: T.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
