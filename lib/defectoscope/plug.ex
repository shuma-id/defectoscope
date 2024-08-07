defmodule Defectoscope.Plug do
  @moduledoc """
  Plug to handle exceptions and push them to the `IncidentsHandler`
  """

  alias Defectoscope.IncidentsHandler
  alias Plug.Conn.WrapperError

  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      defoverridable call: 2

      def call(conn, opts) do
        try do
          super(conn, opts)
        catch
          kind, reason ->
            stack = __STACKTRACE__
            unquote(__MODULE__).handle_error(kind, reason, stack, conn)
            :erlang.raise(kind, reason, stack)
        end
      end
    end
  end

  @doc false
  def handle_error(:error, %WrapperError{} = wrapped_error, _stack, _conn) do
    %{conn: conn, reason: wrapped_reason, stack: stacktrace} = wrapped_error
    handle_error(:error, wrapped_reason, stacktrace, conn)
  end

  @doc false
  def handle_error(kind, reason, stacktrace, conn) do
    params = %{
      kind: kind,
      reason: reason,
      stacktrace: stacktrace,
      conn: conn,
      timestamp: DateTime.utc_now()
    }

    IncidentsHandler.push(%{source: :plug, params: params})
  end
end
