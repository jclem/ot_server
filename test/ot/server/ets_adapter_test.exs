defmodule OT.Server.ETSAdapterTest do
  use ExUnit.Case, async: true
  doctest OT.Server.ETSAdapter

  alias OT.Server.ETSAdapter

  setup do
    {:ok, _} = ETSAdapter.start_link([])
    %{}
  end

  test ".transact calls the enclosing function" do
    result = ETSAdapter.transact("id", fn -> :done end)
    assert result == {:ok, :done}
  end

  test ".rollback raises the error" do
    assert_raise(ETSAdapter.RollbackError, "{:error, \"Error\"}", fn ->
      ETSAdapter.rollback({:error, "Error"})
    end)
  end

  test ".get_conflicting_operations gets conflicting operations" do
    ETSAdapter.insert_operation(%{id: "id"}, {[:op_0], 0}, nil)
    ETSAdapter.insert_operation(%{id: "id"}, {[:op_1], 1}, nil)
    ETSAdapter.insert_operation(%{id: "id"}, {[:op_2], 2}, nil)
    ETSAdapter.insert_operation(%{id: "id2"}, {[:op_2_2], 2}, nil)

    assert ETSAdapter.get_conflicting_operations(%{id: "id"}, 1) ==
      [{[:op_1], 1}, {[:op_2], 2}]
  end

  test ".get_datum fetches the datum" do
    datum = %{id: "id"}
    :ets.insert(:ot_data, {datum[:id], datum})
    assert ETSAdapter.get_datum(datum[:id]) == {:ok, datum}
  end

  test ".get_datum returns an error when not found" do
    assert ETSAdapter.get_datum("id") == {:error, :not_found}
  end

  test ".handle_submit_error returns a retry for a version mismatch" do
    assert ETSAdapter.handle_submit_error({:error, :version_mismatch}, nil, nil) ==
      :retry
  end

  test ".handle_submit_error returns the error for a non-version mismatch" do
    assert ETSAdapter.handle_submit_error({:error, :not_found}, nil, nil) ==
      {:error, :not_found}
  end

  test ".insert_operation inserts the operation of it is valid" do
    assert ETSAdapter.insert_operation(%{id: "id"}, {[1], 1}, nil) == {:ok, {[1], 1}}
    assert ETSAdapter.get_conflicting_operations(%{id: "id"}, 1) == [{[1], 1}]
  end

  test ".insert_operation returns an error for a version mismatch" do
    ETSAdapter.insert_operation(%{id: "id"}, {[1], 1}, nil)
    assert ETSAdapter.insert_operation(%{id: "id"}, {[1], 1}, nil) ==
      {:error, :version_mismatch}
  end

  test ".update_datum updates the datum" do
    datum = %{id: "id", content: "A", version: 0}
    :ets.insert(:ot_data, {datum[:id], datum})
    {:ok, %{id: "id", content: "B", version: 1}} =
      ETSAdapter.update_datum(datum, "B")
    assert ETSAdapter.get_datum("id") ==
      {:ok, %{id: "id", content: "B", version: 1}}
  end
end
