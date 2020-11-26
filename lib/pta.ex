defmodule PTA do
  @moduledoc """
  TODO
  """

  defmodule Amount do
    defstruct quantity: nil,
	          commodity: nil
	
	# TODO: `commodity` should probably be a module. Might help with conversions
	@type t :: %Amount{
	  quantity: float(),
	  commodity: String.t()
	}
  end

  defmodule Account do
    # TODO: add some missing fields
    defstruct name: nil,
	          fullName: nil
	
	@type t :: %Account{
	  name: String.t(),
	  fullName: String.t()
	}
  end

  defmodule Posting do
    defstruct amount: nil,
	          account: nil,
			  tags: nil

	@type t :: %Posting{
	  amount: Amount.t(),
	  account: Account.t(),
	  tags: %{String.t() => String.t()}
	}
  end

  defmodule Transaction do
    defstruct date: nil,
	          payee: nil,
	          postings: nil,
			  tags: nil

	@type t :: %Transaction{
	  date: String.t(),
	  payee: String.t(),
	  postings: list(Posting.t()),
	  tags: %{String.t() => String.t()}
	}
  end

  defmodule Journal do
    defstruct accounts: nil,
	          transactions: nil

	@type t :: %Journal{
	  accounts: %{String.t() => Account.t()},
	  transactions: list(Transaction.t())
	}
  end
end
