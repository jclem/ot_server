defmodule OT.ServerTest do
  use ExUnit.Case
  doctest OT.Server

  alias OT.Server

  setup do
    Application.put_env(:ot_server, :ot_types, %{"text" => OT.Text})
    OT.Server.ETSAdapter.start_link([])
    {:ok, server} = OT.Server.start_link([])
    {:ok, %{server: server}}
  end

  test ".submit_operation submits the operation", %{server: server} do
    datum = %{id: "id", content: "", type: "text", version: 0}
    :ets.insert(:ot_data, {datum[:id], datum})
    Server.submit_operation(server, "id", {[%{i: "A"}], 1})
    {:ok, datum} = Server.get_datum(server, datum[:id])
    assert datum[:content] == "A"
  end

  test ".get_datum gets the datum by ID", %{server: server} do
    datum = %{id: "id", content: "", type: "text", version: 0}
    :ets.insert(:ot_data, {datum[:id], datum})
    assert Server.get_datum(server, datum[:id]) == {:ok, datum}
  end
end
