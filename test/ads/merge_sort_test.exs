defmodule ADS.MergeSortTest do
  use ExUnit.Case

  alias ADS.{Helpers, MergeSort}

  @moduledoc false

  describe "generate_steps/1" do
    test "sorts list of integers" do
      for _ <- 1..10 do
        random_list = Helpers.random_list(100, false, 10)
        {sorted_list, _pid} = MergeSort.generate_steps(random_list)

        assert length(random_list) == length(sorted_list)
        assert sorted?(sorted_list)
      end
    end

    defp sorted?([first, second | rest]) do
      first <= second and sorted?([second | rest])
    end

    defp sorted?(_other) do
      true
    end
  end
end
