defmodule OT.Server.ETSAdapter do
  @moduledoc """
  This is an adapter for OT.Server that stores data and operations in ETS
  tables.

  It is not meant for production use, as all of its data is publicly available
  for testing purposes.
  """

  @behaviour OT.Server.Adapter

  use GenServer

  @ops_table :ot_ops
  @data_table :ot_data

  defmodule RollbackError do
    defexception [:message]

    def exception(error) do
      %__MODULE__{message: inspect(error)}
    end
  end

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ets.new(@data_table, [:named_table, :set, :public])
    :ets.new(@ops_table, [:named_table, :ordered_set, :public])
    {:ok, []}
  end

  @impl OT.Server.Adapter
  def transact(_, func) do
    GenServer.call(__MODULE__, {:transact, func})
  end

  @impl OT.Server.Adapter
  def rollback(err) do
    raise RollbackError, err
  end

  @impl OT.Server.Adapter
  def get_conflicting_operations(%{id: id}, op_vsn) do
    # Compiled from:
    #     :ets.fun2ms(fn {{^id, vsn}, op} when vsn >= op_vsn ->
    #       {op, vsn}
    #     end)
    match_spec = [{
      {{:"$1", :"$2"}, :"$3"},
      [{:>=, :"$2", {:const, op_vsn}}, {:"=:=", {:const, id}, :"$1"}],
      [{{:"$3", :"$2"}}]
    }]

    :ets.select(@ops_table, match_spec)
  end

  @impl OT.Server.Adapter
  def get_datum(id) do
    @data_table
    |> :ets.lookup(id)
    |> case do
      [{^id, datum}] -> {:ok, datum}
      _ -> {:error, :not_found}
    end
  end

  @impl OT.Server.Adapter
  def handle_submit_error({:error, :version_mismatch}, _, _) do
    :retry
  end

  def handle_submit_error(err, _, _) do
    err
  end

  @impl OT.Server.Adapter
  def insert_operation(%{id: id}, {op, vsn}, _meta) do
    if :ets.insert_new(@ops_table, {{id, vsn}, op}) do
      {:ok, {op, vsn}}
    else
      {:error, :version_mismatch}
    end
  end

  @impl OT.Server.Adapter
  def update_datum(datum, content) do
    datum =
      datum
      |> Map.put(:content, content)
      |> Map.put(:version, datum[:version] + 1)

    if :ets.insert(@data_table, {datum[:id], datum}) do
      {:ok, datum}
    else
      {:error, :update_failed}
    end
  end

  @impl GenServer
  def handle_call({:transact, func}, _, state) do
    {:reply, {:ok, func.()}, state}
  end
end
