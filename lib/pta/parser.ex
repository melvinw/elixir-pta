defmodule PTA.Parser do
  @moduledoc """
  TODO
  """
  
  # TODO: Define me

  @spec parse(String.t()) :: PTA.Journal.t()
  def parse(_src) do
	%PTA.Journal{}
  end

  # String.split\2 would be perfect here, but we need to treat newlines as separate tokens.
  @doc """
  Splits the given character list into tokens.

  Returns `list(String.t())`
  """
  @spec tokenize(list(String.t()), list(String.t())) :: list(String.t())
  def tokenize(chars, acc \\ []) do
	case chars do
	  [head | tail] ->
	    cond do
		  head == " " or head == "\t" ->
		    case acc do
	          [_ | _] -> [ (for c <- acc, into: "", do: c) | tokenize(tail, [])]
			  _ -> tokenize(tail, [])
			end
		  head == "\n" ->
		    case acc do
	          [_ | _] -> [ (for c <- acc, into: "", do: c) ] ++ [head | tokenize(tail, [])]
			  _ -> tokenize(tail, [])
			end
		  true ->
	        tokenize(tail, acc ++ [head])
		end
	  _ -> acc
	end
  end
end
