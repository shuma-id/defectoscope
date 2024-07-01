defmodule Defectoscope.LoggerBackend do
  @moduledoc false

  @behaviour :gen_event

  alias Defectoscope.{ErrorHandler, LoggerBackendReportBuilder}

  require Logger

  @handle_levels ~w(error critical emergency alert)a

  @meta_keys ~w(
    application erl_level initial_call registered_name function line
    module pid time file gl domain mfa crash_reason
  )a

  def init(__MODULE__) do
    {:ok, []}
  end

  # Ignore events from other nodes
  def handle_event({_level, gl, {_, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {_, message, _, meta}}, state) when level in @handle_levels do
    %{
      builder: LoggerBackendReportBuilder,
      level: level,
      message: message,
      meta: Map.new(meta),
      metadata: Keyword.drop(meta, @meta_keys),
      timestamp: DateTime.utc_now()
    }
    |> ErrorHandler.push()

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  def handle_call(_messsage, state) do
    {:ok, nil, state}
  end
end
