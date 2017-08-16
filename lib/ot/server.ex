defmodule OT.Server do
  @moduledoc """
  Accepts an incoming operation, transforms it, and persists it to storage.
  """

  use GenServer

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Submit an operation.
  """
  def submit_operation(datum_id, {op, vsn}, meta \\ nil) do
    call_with_worker({:submit_operation, datum_id, {op, vsn}, meta})
  end

  @doc """
  Get a datum.
  """
  def get_datum(id) do
    call_with_worker({:get_datum, id})
  end

  @impl true
  def handle_call(call_args, _from, state) do
    [command | args] = Tuple.to_list(call_args)
    result = apply(OT.Server.Impl, command, args)
    {:reply, result, state}
  end

  defp call_with_worker(call_args) do
    :poolboy.transaction(:ot_worker, fn ot_worker ->
      GenServer.call(ot_worker, call_args)
    end)
  end
end
