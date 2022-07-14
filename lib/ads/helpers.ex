defmodule ADS.Helpers do
  use TypeCheck

  @moduledoc """
  Miscellaneous helper functions.
  """

  @doc """
  Returns a random list of integers.
  """
  @spec random_list(non_neg_integer(), boolean(), non_neg_integer(), non_neg_integer()) ::
          list(integer()) | []
  def random_list(range, fixed_length?, max_length, min_length \\ 1) do
    length =
      if fixed_length? do
        max_length
      else
        Enum.random(min_length..max_length)
      end

    Stream.repeatedly(fn -> Enum.random(-range..range) end)
    |> Enum.take(length)
  end
end
