defmodule Defectoscope.ForwarderTest do
  @moduledoc false

  use Defectoscope.ConnCase

  alias Defectoscope.{Forwarder, PlugReportBuilder, LoggerBackendReportBuilder}

  describe "forward/1" do
    setup do
      Req.Test.stub(Forwarder, fn conn ->
        Req.Test.json(conn, %{status: :ok})
      end)

      :ok
    end

    test "(plug: success)" do
      errors =
        [
          get("/exception"),
          get("/badarith"),
          get("/bad_request"),
          get("/exit"),
          get("/throw")
        ]
        |> Enum.map(&Map.put(&1, :builder, PlugReportBuilder))

      assert {:ok, _} = Forwarder.forward(errors)
    end

    test "(plug: raise exception)" do
      ok = get("/")
      assert catch_error(Forwarder.forward([ok]))
    end

    test "(logger backend)" do
      logger_error = %{
        builder: LoggerBackendReportBuilder,
        level: :error,
        message: ["** (ArithmeticError) bad argument in arithmetic expression"],
        meta: %{
          crash_reason:
            {%ArithmeticError{
               message: "bad argument in arithmetic expression"
             }, [{:erlang, :/, [1, 0], [error_info: %{module: :erl_erts_errors}]}]},
          erl_level: :error
        },
        metadata: [user_params: [1, 0]],
        timestamp: ~U[2024-04-23 08:56:19.327874Z]
      }

      assert {:ok, _} = Forwarder.forward([logger_error])
    end
  end
end
