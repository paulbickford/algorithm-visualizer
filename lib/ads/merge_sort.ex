defmodule ADS.MergeSort do
  use TypeCheck

  alias ADS.Step

  @moduledoc """
  Performs merge sort on list of numbers.

  Returns a sorted list, while also emitting a series of steps
  of the algorithm that allow it to be visually displayed. The
  steps are synchronously emitted to a ADS.Step GenServer that
  can be queried by the display mechanism.
  """

  @doc """
  Generates a series of steps that are sent to a
  ADS.Step GenServer.
  """

  @type parent() :: {level :: integer(), segment :: non_neg_integer()}

  @spec generate_steps(list(integer())) :: {list(integer()), pid()}
  def generate_steps(list) do
    {:ok, steps} = Step.start_link()
    parent = {0, 0}

    values =
      Enum.with_index(list, &{&2, &1})
      |> Map.new()

    steps
    |> Step.add_values(values)

    {sorted_map, _parent} = merge_sort(steps, values, parent)
    Step.finish(steps)
    {Map.values(sorted_map), steps}
  end

  @spec merge_sort(pid(), map(), parent()) :: {map(), parent()}
  def merge_sort(_steps, values, parent) when map_size(values) == 1 do
    {values, parent}
  end

  def merge_sort(steps, values, {p_level, p_segment}) do
    {l_values, r_values} = Enum.split(values, div(map_size(values), 2))

    Step.move_values(
      steps,
      {p_level, p_segment, Enum.to_list(0..(length(l_values) - 1))},
      {p_level + 1, child_segment(p_segment, 0), Enum.to_list(0..(length(l_values) - 1))}
    )

    Step.move_values(
      steps,
      {p_level, p_segment, Enum.to_list(length(l_values)..(map_size(values) - 1))},
      {p_level + 1, child_segment(p_segment, 1), Enum.to_list(0..(length(r_values) - 1))}
    )

    {l_sorted, {l_p_level, l_p_segment}} =
      merge_sort(steps, Map.new(l_values), {p_level + 1, child_segment(p_segment, 0)})

    {r_sorted, {r_p_level, r_p_segment}} =
      merge_sort(steps, Map.new(r_values), {p_level + 1, child_segment(p_segment, 1)})

    merge(
      steps,
      {l_sorted, l_p_level, l_p_segment},
      {r_sorted, r_p_level, r_p_segment}
    )
  end

  @spec merge(
          pid(),
          {map(), non_neg_integer(), non_neg_integer()},
          {map(), non_neg_integer(), non_neg_integer()}
        ) ::
          {map(), parent()}
  def merge(steps, {l_values, l_level, l_segment}, {r_values, r_level, r_segment}) do
    merge_maps(
      steps,
      {l_values, l_level, l_segment, map_size(l_values)},
      {r_values, r_level, r_segment, map_size(r_values)},
      %{}
    )
  end

  @spec merge_maps(
          pid(),
          {map(), non_neg_integer(), non_neg_integer(), non_neg_integer()},
          {map(), non_neg_integer(), non_neg_integer(), non_neg_integer()},
          map()
        ) :: {map(), parent()}
  def merge_maps(
        _steps,
        {l_values, l_level, l_segment, _l_length},
        {r_values, _r_level, _r_segment, _r_length},
        sorted
      )
      when map_size(l_values) == 0 and map_size(r_values) == 0 do
    child = {l_level + 1, div(l_segment, 2)}

    {sorted, child}
  end

  def merge_maps(
        steps,
        {l_values, l_level, l_segment, l_length},
        {r_values, r_level, r_segment, r_length},
        sorted
      )
      when map_size(l_values) == 0 do
    r_cell = r_length - map_size(r_values)
    child_level = r_level + 1
    child_segment = div(r_segment, 2)
    {r_rest, _r_index, r_value} = pop_first(r_values)
    {new_sorted, sorted_index} = put_next(sorted, r_value)

    steps
    |> Step.move_value(
      {r_level, r_segment, r_cell},
      {child_level, child_segment, sorted_index}
    )
    |> Step.mark_sorted({child_level, child_segment, sorted_index})

    merge_maps(
      steps,
      {l_values, l_level, l_segment, l_length},
      {r_rest, r_level, r_segment, r_length},
      new_sorted
    )
  end

  def merge_maps(
        steps,
        {l_values, l_level, l_segment, l_length},
        {r_values, r_level, r_segment, r_length},
        sorted
      )
      when map_size(r_values) == 0 do
    l_cell = l_length - map_size(l_values)
    child_level = l_level + 1
    child_segment = div(l_segment, 2)
    {l_rest, _l_index, l_value} = pop_first(l_values)
    {new_sorted, sorted_index} = put_next(sorted, l_value)

    steps
    |> Step.move_value(
      {l_level, l_segment, l_cell},
      {child_level, child_segment, sorted_index}
    )
    |> Step.mark_sorted({child_level, child_segment, sorted_index})

    merge_maps(
      steps,
      {l_rest, l_level, l_segment, l_length},
      {r_values, r_level, r_segment, r_length},
      new_sorted
    )
  end

  def merge_maps(
        steps,
        {l_values, l_level, l_segment, l_length},
        {r_values, r_level, r_segment, r_length},
        sorted
      ) do
    l_cell = l_length - map_size(l_values)
    r_cell = r_length - map_size(r_values)
    child_level = l_level + 1
    child_segment = div(l_segment, 2)

    {l_rest, _l_index, l_value} = pop_first(l_values)
    {r_rest, _r_index, r_value} = pop_first(r_values)

    if l_value < r_value do
      {new_sorted, sorted_index} = put_next(sorted, l_value)

      steps
      |> Step.move_value(
        {l_level, l_segment, l_cell},
        {child_level, child_segment, sorted_index}
      )
      |> Step.mark_sorted({child_level, child_segment, sorted_index})

      merge_maps(
        steps,
        {l_rest, l_level, l_segment, l_length},
        {r_values, r_level, r_segment, r_length},
        new_sorted
      )
    else
      {new_sorted, sorted_index} = put_next(sorted, r_value)

      steps
      |> Step.move_value(
        {r_level, r_segment, r_cell},
        {child_level, child_segment, sorted_index}
      )
      |> Step.mark_sorted({child_level, child_segment, sorted_index})

      merge_maps(
        steps,
        {l_values, l_level, l_segment, l_length},
        {r_rest, r_level, r_segment, r_length},
        new_sorted
      )
    end
  end

  @spec child_segment(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp child_segment(parent_segment, child_segment) do
    parent_segment * 2 + child_segment
  end

  @spec pop_first(map()) :: {map(), non_neg_integer(), integer()}
  defp pop_first(values) do
    key =
      Map.keys(values)
      |> Enum.min()

    {value, values} = Map.pop(values, key)
    {values, key, value}
  end

  @spec put_next(map(), integer()) :: {map(), non_neg_integer()}
  defp put_next(values, value) do
    key =
      if map_size(values) == 0 do
        -1
      else
        Map.keys(values)
        |> Enum.max()
      end

    {Map.put(values, key + 1, value), key + 1}
  end
end
