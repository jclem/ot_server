defmodule OT.Server.Impl do
  @moduledoc """
  Implements the logic of accepting, transforming, and persisting OT operations.
  """

  @adapter Application.get_env(:ot_server, :adapter, OT.Server.ETSAdapter)
  @max_retries Application.get_env(:ot_server, :max_retries)

  @doc """
  Get a datum.
  """
  def get_datum(id) do
    @adapter.get_datum(id)
  end

  @doc """
  Submit an operation, transforming it against concurrent operations, if
  necessary.
  """
  def submit_operation(datum_id, op_vsn, op_meta, retries \\ 0)

  def submit_operation(_, _, _, retries) when retries > @max_retries do
    {:error, :max_retries_exceeded}
  end

  def submit_operation(datum_id, {op, vsn}, op_meta, retries) do
    txn_result =
      @adapter.transact(fn ->
        case attempt_submit_operation(datum_id, {op, vsn}, op_meta) do
          {:ok, new_op} -> new_op
          {:error, err} -> @adapter.rollback(err)
        end
      end)

    case txn_result do
      {:ok, new_op} ->
        {:ok, new_op}
      {:error, err} ->
        case @adapter.handle_submit_error(err, datum_id, {op, vsn}) do
          :retry -> submit_operation(datum_id, {op, vsn}, retries + 1)
          err -> err
        end
    end
  end

  defp attempt_submit_operation(datum_id, {op, vsn}, op_meta) do
    with {:ok, datum} <- @adapter.get_datum(datum_id),
         {:ok, type}  <- lookup_type(Map.get(datum, :type)),
         {:ok, vsn}   <- check_datum_version(Map.get(datum, :version), vsn),
         {op, vsn}    = get_new_operation(datum, {op, vsn}, type),
         {:ok, datum} <- update_datum(datum, op, type) do
      @adapter.insert_operation(datum, {op, vsn}, op_meta)
    end
  end

  defp lookup_type(type_key) do
    case Application.get_env(:ot_server, :ot_types, %{})[type_key] do
      type when not is_nil(type) -> {:ok, type}
      _ -> {:error, :type_not_found}
    end
  end

  defp check_datum_version(datum_vsn, op_vsn) do
    if op_vsn > datum_vsn + 1 do
      {:error, {:version_mismatch, op_vsn, datum_vsn}}
    else
      {:ok, op_vsn}
    end
  end

  defp get_new_operation(datum, {op, vsn}, type) do
    case @adapter.get_conflicting_operations(datum, vsn) do
      [] ->
        {op, vsn}
      conflicting_ops ->
        new_vsn =
          conflicting_ops
          |> Enum.max_by(&(elem(&1, 1)))
          |> elem(1)
          |> Kernel.+(1)

        new_op =
          conflicting_ops
          |> Enum.reduce(op, &type.transform(&2, elem(&1, 0), :left))

        {new_op, new_vsn}
    end
  end

  defp update_datum(datum, op, type) do
    case type.apply(Map.get(datum, :content), op) do
      {:ok, content} ->
        @adapter.update_datum(datum, content)
      err ->
        err
    end
  end
end
