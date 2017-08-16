defmodule OT.Server.Adapter do
  @type datum :: any
  @type operation :: OT.Operation.t
  @type version :: pos_integer
  @type op_vsn :: {operation, version}

  @callback transact((... -> any)) :: {:ok, any} | {:error, any}
  @callback rollback(any) :: no_return
  @callback get_datum(any) :: {:ok, datum} | {:error, any}
  @callback get_conflicting_operations(datum, version) :: [{operation, version}]
  @callback update_datum(datum, any) :: {:ok, datum} | {:error, any}
  @callback insert_operation(datum, {OT.Operation.t, version}, any) :: {:ok, any} | {:error, any}
  @callback handle_submit_error(any, any, op_vsn) :: :retry | {:error, any}
end
