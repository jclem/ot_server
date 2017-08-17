defmodule OT.Server.Adapter do
  @moduledoc """
  An adapter behaviour for interacting with peristed data in an operational
  transformation system.
  """

  alias OT.Server

  @doc """
  Call a function inside of a transaction.

  This is useful for adapters that use databases that support transactions. All
  of the other adapter functions (other than `c:handle_submit_error/3`) will
  be call called in the function passed to this function.

  This is a good place to implement locking to ensure that only a single
  operation is processed at a time per document, a requirement of this OT
  system.
  """
  @callback transact(id :: Server.datum_id, (() -> any)) :: {:ok, any} | {:error, any}

  @doc """
  Roll a transaction back.

  This will be called when the attempt to submit an operation fails—for adapters
  without real transaction support, they must choose how to repair their data
  at this stage, since `c:update_datum/2` may have been called, but
  `c:insert_operation/3` may have failed.
  """
  @callback rollback(any) :: no_return

  @doc """
  Get the datum identified by the ID.
  """
  @callback get_datum(id :: Server.datum_id) :: {:ok, Server.datum} | {:error, any}

  @doc """
  Get any conflicting operations for the given datum at the given version.

  In a proper OT system, this means any operation for the given datum
  whose version is greater than or equal to the given version.

  The function must return a list of `t:OT.Server.operation_info/0`s.
  """
  @callback get_conflicting_operations(datum :: Server.datum, Server.version)
    :: [Server.operation_info]

  @doc """
  Update the `t:OT.Server.datum/0` with the given content and increment its
  `t:OT.Server.version/0`.
  """
  @callback update_datum(datum :: Server.datum, any) :: {:ok, Server.datum} | {:error, any}

  @doc """
  Insert the given `t:OT.Server.operation/0` into persistence.

  Any metadata that was originally passed to `OT.Server.submit_operation/3` will
  also be passed to the adapter.

  On a successful submission, this value is what will be returned from
  `OT.Server.submit_operation/3`.
  """
  @callback insert_operation(datum :: Server.datum, Server.operation_info, any) :: {:ok, any} | {:error, any}

  @doc """
  Handle a submission error.

  If the error passed to this function constitutes a scenario in which the
  submission should be tried again, return `:retry`. Otherwise, return a tagged
  error tuple and the call to `OT.Server.submit_operation/3` will fail.
  """
  @callback handle_submit_error(any, any, Server.operation_info) :: :retry | {:error, any}
end
