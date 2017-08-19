defmodule OT.Server do
  @moduledoc """
  A safe API for interacting with operations and the data they operate against.
  """

  use GenServer

  @typedoc """
  A map containing OT-related information.

  This map must contain at least three keys:

  - `type`: A string representing the OT type, which will be used to find the
    appropriate OT module.
  - `version`: A non-negative integer representing the current `t:version/0` of
    the datum.
  - `content`: The contents of the datum that `t:operation/0`s will be applied
    to.
  """
  @type datum :: %{type: String.t, version: non_neg_integer, content: any}

  @typedoc """
  A piece of information that can uniquely identify a `t:datum/0`.
  """
  @type datum_id :: any

  @typedoc """
  A list of units of work performed against a single piece of data (a
  `t:datum/0`).
  """
  @type operation :: [any]

  @typedoc """
  A non-negative integer representing an operation or `t:datum/0` version.
  """
  @type version :: non_neg_integer

  @typedoc """
  A tuple representing an `t:operation/0` and its `t:version/0`.
  """
  @type operation_info :: {operation, version}

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Submit an operation.

  ## Example

      iex> {:ok, pid} = OT.Server.start_link([])
      iex> :ets.insert(:ot_data,
      ...>   {"id", %{id: "id", content: "Hllo, ", type: "text", version: 0}})
      iex> OT.Server.submit_operation(pid, "id", {[1, %{i: "e"}], 1})
      iex> OT.Server.submit_operation(pid, "id", {[6, %{i: "world."}], 1})
      {:ok, {[7, %{i: "world."}], 2}}
      iex> OT.Server.get_datum(pid, "id")
      {:ok, %{id: "id", content: "Hello, world.", type: "text", version: 2}}

  If the operation succeeds, a tuple will be returned with the operation and
  its version. Otherwise, an error will be returned.
  """
  @spec submit_operation(pid, any, {OT.Operation.t, pos_integer}, any) ::
    {:ok, {OT.Operation.t, pos_integer}} | {:error, any}
  def submit_operation(pid, datum_id, {op, vsn}, meta \\ nil) do
    GenServer.call(pid, {:submit_operation, datum_id, {op, vsn}, meta})
  end

  @doc """
  Get a datum.

  This will call the configured adapter's `c:OT.Server.Adapter.get_datum/1`
  function and return that value.

  ## Example

      iex> {:ok, pid} = OT.Server.start_link([])
      iex> :ets.insert(:ot_data, {"id", %{id: "id"}})
      iex> OT.Server.get_datum(pid, "id")
      {:ok, %{id: "id"}}

  If the datum is found, it will be returned. Otherwise, an error is returned.
  Also, note that this function does get called in a worker, so shares worker
  bandwidth with `submit_operation/3`.
  """
  @spec get_datum(pid, any) :: {:ok, any} | {:error, any}
  def get_datum(pid, id) do
    GenServer.call(pid, {:get_datum, id})
  end

  @impl true
  def handle_call(call_args, _from, state) do
    [command | args] = Tuple.to_list(call_args)
    result = apply(OT.Server.Impl, command, args)
    {:reply, result, state}
  end
end
