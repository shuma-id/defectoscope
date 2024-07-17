defmodule Defectoscope.ObanLogger do
  @moduledoc false

  alias Defectoscope.{ErrorHandler, ObanLoggerReportBuilder}

  @doc """
  Attach the Oban logger to handle Oban errors
  """
  @spec attach() :: :ok
  def attach do
    :telemetry.attach(
      "defectoscope-oban-errors",
      [:oban, :job, :exception],
      &__MODULE__.handle_event/4,
      []
    )
  end

  def handle_event([:oban, :job, :exception], _measure, meta, _) do
    %{
      builder: ObanLoggerReportBuilder,
      kind: meta.kind,
      reason: meta.reason,
      stacktrace: meta.stacktrace,
      timestamp: DateTime.utc_now()
    }
    |> ErrorHandler.push()
  end
end
