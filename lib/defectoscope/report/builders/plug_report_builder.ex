defmodule Defectoscope.PlugReportBuilder do
  @moduledoc false

  @behaviour Defectoscope.ReportBuilderBehaviour

  alias Defectoscope.Report
  alias Defectoscope.Util.SensitiveDataFilter

  @type params :: %{
          kind: atom(),
          reason: any(),
          stack: list(),
          conn: Plug.Conn.t(),
          timestamp: DateTime.t()
        }

  @doc """
  Build a new report from a plug
  """
  @impl true
  @spec new(params) :: Report.t()
  def new(params) do
    %Report{
      kind: format_kind(params),
      level: :error,
      message: format_message(params),
      phoenix_params: format_phoenix_params(params),
      stacktrace: format_stacktrace(params),
      timestamp: format_timestamp(params)
    }
  end

  # Error kind
  defp format_kind(%{reason: reason} = _params) when is_atom(reason), do: reason
  defp format_kind(%{reason: reason} = _params) when is_struct(reason), do: reason.__struct__

  # Error message
  defp format_message(%{kind: kind, reason: reason, stack: stack} = _params) do
    Exception.format_banner(kind, reason, stack)
  end

  # Phoenix request params
  defp format_phoenix_params(%{conn: nil} = _params), do: %{}

  defp format_phoenix_params(%{conn: conn, reason: reason} = _params) do
    %{
      status: Plug.Exception.status(reason),
      method: conn.method,
      path_info: conn.path_info,
      request_path: conn.request_path,
      query_string: conn.query_string |> SensitiveDataFilter.filter_query_string(),
      params: format_conn_params(conn.params),
      req_headers: format_req_headers(conn.req_headers) |> SensitiveDataFilter.filter_headers(),
      session: format_session(conn.private)
    }
  end

  # Stacktrace
  defp format_stacktrace(%{stack: stack} = _params) do
    stack
    |> Exception.format_stacktrace()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end

  # Timestamp when error happened
  defp format_timestamp(%{timestamp: timestamp} = _params), do: timestamp
  defp format_timestamp(_error), do: DateTime.utc_now()

  # Request params
  defp format_conn_params(%Plug.Conn.Unfetched{} = _conn_params), do: %{}

  defp format_conn_params(conn_params) do
    SensitiveDataFilter.filter_phoenix_params(conn_params)
  end

  # Request headers
  defp format_req_headers(req_headers) do
    Enum.into(req_headers, %{})
  end

  # Request session
  defp format_session(%{plug_session: session} = _private), do: session
  defp format_session(_private), do: %{}
end
