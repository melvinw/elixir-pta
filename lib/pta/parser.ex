defmodule PTA.Parser do
  @moduledoc """
  TODO
  """

  # Partition `tokens` at the first token for which `pred` evaluates to true.
  # If `inclusive` is true, the token that matched `pred` will be included in the second returned partition.
  def _eat(tokens, pred \\ fn p -> p == "\n" end, inclusive \\ false) do
    case tokens do
      [h | tail] ->
        if pred.(h) do
          if inclusive do
            {[], [h] ++ tail}
          else
            {[], tail}
          end
        else
          {acc, remaining} = _eat(tail, pred, inclusive)
          {[h | acc], remaining}
        end

      _ ->
        {[], tokens}
    end
  end

  @doc """
  Parses the journal in `src` and returns a `PTA.Journal` containing the accounts and transactions found.
  """
  @spec parse(String.t()) :: {:ok, PTA.Journal.t()}
  @spec parse(String.t()) :: {:error, String.t()}
  def parse(src) do
    tokens = _tokenize(String.split(src, "", trim: true))
    _journal(tokens)
  end

  @spec _journal(list(String.t())) :: {:ok, PTA.Journal.t()}
  @spec _journal(list(String.t())) :: {:error, String.t()}
  def _journal(tokens) do
    case tokens do
      [_ | _] ->
        case _journal_item(tokens) do
          {:ok, %PTA.Account{} = a, remaining} ->
            case _journal(remaining) do
              {:ok, j} ->
                {:ok, %PTA.Journal{accounts: [a | j.accounts], transactions: j.transactions}}

              {:error, reason} ->
                {:error, reason}
            end

          {:ok, %PTA.Transaction{} = t, remaining} ->
            case _journal(remaining) do
              {:ok, j} ->
                {:ok, %PTA.Journal{accounts: j.accounts, transactions: [t | j.transactions]}}

              {:error, reason} ->
                {:error, reason}
            end

          {:ok, remaining} ->
            case _journal(remaining) do
              {:ok, j} ->
                {:ok, j}

              {:error, reason} ->
                {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      [] ->
        {:ok, %PTA.Journal{accounts: [], transactions: []}}

      _ ->
        {:error, "missing token list"}
    end
  end

  @spec _journal_item(list(String.t())) :: {:ok, PTA.Transaction.t(), list(String.t())}
  @spec _journal_item(list(String.t())) :: {:ok, PTA.Account.t(), list(String.t())}
  @spec _journal_item(list(String.t())) :: {:ok, list(String.t())}
  @spec _journal_item(list(String.t())) :: {:error, String.t()}
  def _journal_item(tokens) do
    case tokens do
      [head | tail] ->
        cond do
          String.match?(head, ~r/\d{4}\/\d{2}\/\d{1,2}/) ->
            case _transaction(tokens) do
              {:ok, t, remaining} -> {:ok, t, remaining}
              {:error, reason} -> {:error, reason}
            end

          head == "\n" ->
            {:ok, tail}

          head == ";" ->
            {_, remaining} = _eat(tokens)
            {:ok, remaining}

          head == "account" ->
            # TODO: process account stanzas
            {_, remaining} = _eat(tokens)
            {:ok, remaining}

          head == "include" ->
            # TODO: process includes
            {_, remaining} = _eat(tokens)
            {:ok, remaining}

          true ->
            {:error, "got unknown token"}
        end

      _ ->
        {:error, "missing token list"}
    end
  end

  @spec _transaction(list(String.t())) :: {:ok, PTA.Transaction.t(), list(String.t())}
  @spec _transaction(list(String.t())) :: {:error, String.t()}
  def _transaction(tokens) do
    case tokens do
      [head | tail] ->
        {acc, leftover} = _eat(tail)

        case _postings(leftover) do
          {:ok, postings, remaining} ->
            {
              :ok,
              %PTA.Transaction{
                date: head,
                cleared: hd(acc) != "!",
                payee:
                  case acc do
                    [h | t] when h == "!" or h == "*" -> Enum.join(t, " ")
                    _ -> Enum.join(acc, " ")
                  end,
                postings: postings
              },
              remaining
            }

          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        {:error, "missing token list"}
    end
  end

  @spec _transaction(list(String.t())) :: {:ok, list(PTA.Posting.t()), list(String.t())}
  @spec _transaction(list(String.t())) :: {:error, String.t()}
  def _postings(tokens) do
    case _posting(tokens) do
      {:ok, p, remaining} ->
        case _postings(remaining) do
          {:ok, postings, leftover} -> {:ok, [p | postings], leftover}
          {:error, _} -> {:ok, [p], remaining}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec _posting(list(String.t())) :: {:ok, PTA.Posting.t(), list(String.t())}
  @spec _posting(list(String.t())) :: {:error, String.t()}
  def _posting(tokens) do
    {acc, remaining} = _eat(tokens)

    cond do
      acc == [] ->
        {:error, "empty token list"}

      String.match?(hd(acc), ~r/\d{4}\/\d{2}\/\d{1,2}/) ->
        {:error, "end of transaction"}

      true ->
        # TODO: parse tags from `comment_parts`
        {posting_parts, comment_parts} = _eat(acc, fn p -> p == ";" end)

        comment =
          if length(comment_parts) > 0 do
            Enum.join(comment_parts, " ")
          else
            nil
          end

        {account_parts, amount_parts} =
          _eat(posting_parts, fn p -> String.match?(p, ~r/^(-?\d+\.?\d*)(.*)$/) end,
            inclusive: true
          )

        account =
          case account_parts do
            [] -> nil
            _ -> Enum.join(account_parts, " ")
          end

        posting_parts =
          case account_parts do
            [] -> amount_parts
            _ -> [account] ++ amount_parts
          end

        case posting_parts do
          [account] ->
            {:ok, %PTA.Posting{account: account, comment: comment}, remaining}

          [account, trailer] ->
            case Regex.run(~r/^(-?\d+\.?\d*)(.*)$/, trailer) do
              [_, quant, commodity] ->
                {:ok,
                 %PTA.Posting{
                   account: account,
                   amount: %PTA.Amount{quantity: Float.parse(quant), commodity: commodity},
                   comment: comment
                 }, remaining}

              _ ->
                {:error, "invalid posting amount"}
            end

          [account, quant, commodity] ->
            {:ok,
             %PTA.Posting{
               account: account,
               amount: %PTA.Amount{quantity: Float.parse(quant), commodity: commodity},
               comment: comment
             }, remaining}

          [] when comment != nil ->
            {:ok, %PTA.Posting{comment: comment}, remaining}

          _ ->
            {:error, "invalid posting"}
        end
    end
  end

  # Splits the given character list into tokens.
  # String.split\2 would be perfect here, but we need to treat newlines as separate tokens.
  @spec _tokenize(list(String.t()), list(String.t())) :: list(String.t())
  def _tokenize(chars, acc \\ []) do
    case chars do
      [head | tail] ->
        cond do
          head == " " or head == "\t" ->
            case acc do
              [_ | _] -> [for(c <- acc, into: "", do: c) | _tokenize(tail, [])]
              _ -> _tokenize(tail, [])
            end

          head == "\n" or head == ";" ->
            case acc do
              [_ | _] -> [for(c <- acc, into: "", do: c)] ++ [head | _tokenize(tail, [])]
              _ -> [head | _tokenize(tail, [])]
            end

          true ->
            _tokenize(tail, acc ++ [head])
        end

      _ ->
        acc
    end
  end
end
