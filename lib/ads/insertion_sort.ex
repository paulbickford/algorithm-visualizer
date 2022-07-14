defmodule ADS.InsertionSort do
  use TypeCheck

  alias ADS.Step

  @moduledoc """
  Performs insertion sort on list of numbers.

  Returns a sorted list, while also emitting a series of steps
  of the algorithm that allow it to be visually displayed. The
  ADS.Step GenServer can be queried by the display mechanism.
  """

  @doc """
  Generates a series of steps that are sent to a
  ADS.Step GenServer.
  """
  @spec generate_steps(list(integer())) :: {list(integer()), pid()}
  def generate_steps(list) do
    {:ok, steps} = Step.start_link()
    list_length = length(list)

    [sorted | unsorted] = Enum.with_index(list, &{&2, &1})
    sorted = Map.new([sorted])
    unsorted = Map.new(unsorted)

    steps
    |> Step.add_values(Map.merge(sorted, unsorted))
    |> Step.add_temp_cells()
    |> Step.mark_sorted({0, 0, 0})

    {insert_selected_item(steps, {sorted, unsorted}, list_length, 1), steps}
  end

  defp insert_selected_item(steps, {sorted, unsorted}, _list_length, _cursor)
       when map_size(unsorted) == 0 do
    Step.finish(steps)
    Map.values(sorted)
  end

  defp insert_selected_item(steps, {sorted, unsorted}, list_length, cursor) do
    {selected_value, unsorted} = Map.pop(unsorted, cursor)

    steps
    |> Step.move_value({0, 0, cursor}, {1, 0, cursor})

    {moved_sorted, insertion_index} =
      Enum.reduce_while((cursor - 1)..0, {%{}, cursor - 1}, fn i, {moved, _index} ->
        if sorted[i] > selected_value do
          Step.move_value(steps, {1, 0, i + 1}, {1, 0, i})

          i == 0 || Step.compare(steps, {0, 0, i}, {1, 0, i}, :gt)
          Step.move_value(steps, {0, 0, i}, {0, 0, i + 1})
          Step.mark_sorted(steps, {0, 0, i + 1})

          {:cont, {Map.put(moved, i + 1, sorted[i]), i}}
        else
          {:halt, {moved, i + 1}}
        end
      end)

    sorted =
      sorted
      |> Map.merge(moved_sorted)
      |> Map.put(insertion_index, selected_value)

    if insertion_index > 0 do
      steps
      |> Step.move_value({1, 0, insertion_index}, {1, 0, insertion_index - 1})
      |> Step.compare({0, 0, insertion_index - 1}, {1, 0, insertion_index - 1}, :gt)
      |> Step.mark_sorted({0, 0, insertion_index - 1})
      |> Step.move_value({1, 0, insertion_index - 1}, {1, 0, insertion_index})
    end

    Step.move_value(steps, {1, 0, insertion_index}, {0, 0, insertion_index})
    Step.mark_sorted(steps, {0, 0, insertion_index})

    insert_selected_item(steps, {sorted, unsorted}, list_length, cursor + 1)
  end
end
