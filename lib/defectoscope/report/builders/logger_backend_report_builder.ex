defmodule Defectoscope.LoggerBackendReportBuilder do
  @moduledoc false

  @behaviour Defectoscope.ReportBuilderBehaviour

  alias Defectoscope.Report

  @type params :: %{
          level: atom(),
          message: String.t(),
          meta: map(),
          metadata: Keyword.t(),
          timestamp: DateTime.t()
        }

  @doc """
  Build a new report from a log event
  """
  @impl true
  @spec new(params) :: Report.t()
  def new(params) do
    %{level: level, message: message, meta: meta, metadata: metadata, timestamp: timestamp} =
      params

    reason = reason_from_meta(meta)
    stacktrace = stacktrace_from_meta(meta)

    %Report{
      kind: format_kind(reason),
      level: level,
      message: (format_message(reason, stacktrace) || message) |> IO.iodata_to_binary(),
      stacktrace: format_stacktrace(stacktrace),
      timestamp: timestamp,
      meta: inspect(metadata)
    }
  end

  # Return the reason from meta or `nil`
  defp reason_from_meta(%{crash_reason: {reason, _}} = _meta)
       when is_exception(reason) or is_atom(reason),
       do: reason

  defp reason_from_meta(_meta), do: nil

  # Return the stacktrace from meta or `[]`
  defp stacktrace_from_meta(%{crash_reason: {_, stacktrace}} = _meta) when is_list(stacktrace),
    do: stacktrace

  defp stacktrace_from_meta(_meta), do: []

  # Return the kind from crash_reason
  defp format_kind(reason) when is_atom(reason) and not is_nil(reason), do: reason
  defp format_kind(reason) when is_struct(reason), do: reason.__struct__
  defp format_kind(_reason), do: :unknown_error_type

  # Return the message from reason_crash or `nil`
  defp format_message(nil = _reason, _stacktrace), do: nil

  defp format_message(reason, stacktrace) do
    Exception.format_banner(:error, reason, stacktrace)
  end

  # Return the stacktrace
  defp format_stacktrace(stacktrace) do
    stacktrace
    |> Exception.format_stacktrace()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end
end
