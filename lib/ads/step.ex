defmodule ADS.Step do
  use GenServer
  use TypeCheck

  @moduledoc """
  Records list of steps taken in algorithm and translates them to
  a list of steps fro their visualization.

  Receives the original list to be sorted as a map, with the keys
  representing an index from 0 to n-1.

  Receives individual steps from the algorithm and adds them
  the to queue.

  Terms:

  algorithm
    Type of algorithm visualization, such as:
      in-place
      one level per step
      tree

  level
    A group containing a complete set of given values arranged in one or
    more disjoint segments. The root (zeroth) level contains one segment
    of the given indicies in original order. Each subsequent level epresents
    the result of processing the previous level. In-place algorithms have
    only one level plus a temporary level.

  segment
    A group of all, or a subset, of the given indicies.

  bin
    A visual representation of a cell with a value in it.

  cell
    A position within a segment representing one of the original indicies
    and its value.

  child
    The area reserved for the child segments of its parent segment(s).

  comparison
    The comparison of the values of two cells.

  move
    The movement of a value (or technically, its bin) from a cell in a segment
    to a cell in a segment in the next layer.
  """

  @type levels() :: %{index() => level()}
  @type level() :: %{index() => segment_length()}
  @type segment_length() :: non_neg_integer()

  @type values() :: %{index() => value}
  @type value() :: any()

  @type index() :: non_neg_integer()
  @type step() :: {atom(), any()} | {atom()}

  # Client

  @doc """
  Starts the module instance.
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
  Returns the step at the head of the queue.
  """
  @spec next_step(pid()) :: step() | :empty
  def next_step(pid) do
    GenServer.call(pid, :dequeue)
  end

  @doc """
  Enqueues a step to create a temporary cell.
  """
  @spec add_temp_cells(pid()) :: pid()
  def add_temp_cells(pid) do
    GenServer.call(pid, :add_temp_cells)
    pid
  end

  @doc """
  Enqueues a step to insert values into the data structure.
  """
  @spec add_values(pid(), %{non_neg_integer() => integer()}) :: pid()
  def add_values(pid, values) do
    GenServer.call(pid, {:add_values, values})
    pid
  end

  @doc """
  Enqueues a step to compare the values of two cells.
  """
  @spec compare(
          pid(),
          {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          atom()
        ) :: pid()
  def compare(pid, cell1, cell2, comparator) do
    GenServer.call(pid, {:enqueue, {:compare, {cell1, cell2, comparator}}})
    pid
  end

  @doc """
  Enqueues a step to signal the finish of the procedure.
  """
  @spec finish(pid()) :: :ok
  def finish(pid) do
    GenServer.call(pid, :finish)
  end

  @doc """
  Enqueues a step to mark given cell as selected.
  """
  @spec mark_selected(pid(), {non_neg_integer(), non_neg_integer(), non_neg_integer()}) ::
          pid()
  def mark_selected(pid, cell) do
    GenServer.call(pid, {:enqueue, {:mark_selected, cell}})
    pid
  end

  @doc """
  Enqueues a step to mark given cell as sorted.
  """
  @spec mark_sorted(pid(), {non_neg_integer(), non_neg_integer(), non_neg_integer()}) :: pid()
  def mark_sorted(pid, cell) do
    GenServer.call(pid, {:enqueue, {:mark_sorted, cell}})
    pid
  end

  @doc """
  Enqueues a step to move a value from one cell to another.
  """
  @spec move_value(
          pid(),
          {index(), index(), index()},
          {index(), index(), index()}
        ) :: pid()
  def move_value(pid, from, to) do
    GenServer.call(pid, {:move_value, from, to})
    pid
  end

  @doc """
  Enqueues a step to move values to another segment.
  """
  @spec move_values(pid(), {index(), index(), any()}, {index(), index(), any()}) ::
          pid()
  def move_values(pid, from, to) do
    GenServer.call(pid, {:move_values, from, to})
    pid
  end

  @doc """
  Enqueues a step to remove a temporary cell.
  """
  @spec remove_temp_cell(pid()) :: :ok
  def remove_temp_cell(pid) do
    GenServer.call(pid, {:enqueue, {:remove_temp_cell}})
  end

  # Server

  @impl GenServer
  @spec init(any()) ::
          {:ok,
           %{
             levels: levels(),
             queue: :queue.queue(step() | nil),
             queue_front: []
           }}
  def init(_args) do
    state = %{
      levels: %{0 => %{0 => 0}},
      queue: :queue.new(),
      queue_front: []
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        :add_temp_cells,
        _from,
        %{levels: levels, queue: queue, queue_front: queue_front} = state
      ) do
    length = levels[0][0]
    levels = Map.put(levels, 1, %{0 => length})

    queue_front = [{:hide_segments} | queue_front]

    {:reply, :ok, Map.merge(state, %{levels: levels, queue: queue, queue_front: queue_front})}
  end

  @impl GenServer
  def handle_call(
        {:add_values, values},
        _from,
        %{
          levels: levels,
          queue: queue
        } = state
      ) do
    values =
      for {index, val} <- values, into: %{} do
        {{0, 0, index}, %{value: val, style: nil}}
      end

    queue =
      queue
      |> enqueue({:add_values, values})

    levels = put_in(levels[0][0], map_size(values))

    {:reply, :ok, Map.merge(state, %{levels: levels, queue: queue})}
  end

  @impl GenServer
  def handle_call(:dequeue, _from, %{queue: queue} = state) do
    case :queue.out(queue) do
      {{:value, item}, queue} ->
        {:reply, item, Map.merge(state, %{queue: queue})}

      {:empty, queue} ->
        {:reply, :empty, Map.merge(state, %{queue: queue})}
    end
  end

  @impl GenServer
  def handle_call({:enqueue, item}, _from, %{queue: queue} = state) do
    queue = enqueue(queue, item)

    {:reply, :ok, Map.merge(state, %{queue: queue})}
  end

  @impl GenServer
  def handle_call(
        :finish,
        _from,
        %{levels: levels, queue: queue, queue_front: queue_front} = state
      ) do
    queue_front = List.flatten([{:add_levels, levels}, queue_front, {:start}])

    queue = Enum.reduce(queue_front, queue, fn item, acc -> enqueue_front(acc, item) end)

    queue = enqueue(queue, {:finish})
    {:reply, :ok, Map.merge(state, %{queue: queue})}
  end

  @impl GenServer
  def handle_call(
        {:move_value, {from_level, from_segment, from_cell}, {to_level, to_segment, to_cell}},
        _from,
        %{
          levels: levels,
          queue: queue
        } = state
      ) do
    levels =
      case exists_level?(levels, to_level) do
        true ->
          levels

        false ->
          add_level(levels, to_level)
      end

    levels = increment_segment_length(levels, {to_level, to_segment, to_cell})

    queue =
      enqueue(
        queue,
        {:move_value, {from_level, from_segment, from_cell}, {to_level, to_segment, to_cell}}
      )

    {:reply, :ok, Map.merge(state, %{levels: levels, queue: queue})}
  end

  @impl GenServer
  def handle_call(
        {:move_values, {from_level, from_segment, from_cells}, {to_level, to_segment, to_cells}},
        _from,
        %{
          levels: levels,
          queue: queue
        } = state
      ) do
    levels =
      case exists_level?(levels, to_level) do
        true ->
          levels

        false ->
          add_level(levels, to_level)
      end

    levels = put_in(levels[to_level][to_segment], length(to_cells))

    queue =
      enqueue(
        queue,
        {:move_values, {from_level, from_segment, from_cells}, {to_level, to_segment, to_cells}}
      )

    {:reply, :ok, Map.merge(state, %{levels: levels, queue: queue})}
  end

  @spec add_level(map(), non_neg_integer()) :: map()
  defp add_level(levels, level) do
    Map.put(levels, level, %{0 => 0})
  end

  defp enqueue(queue, item) do
    :queue.in(item, queue)
  end

  defp enqueue_front(queue, item) do
    :queue.in_r(item, queue)
  end

  @spec increment_segment_length(map(), {non_neg_integer(), non_neg_integer(), non_neg_integer()}) ::
          map()
  defp increment_segment_length(levels, {level, segment, cell}) do
    case levels[level][segment] do
      nil ->
        update_in(levels[level], &Map.put(&1, segment, 1))

      _ ->
        if cell + 1 > levels[level][segment] do
          put_in(levels[level][segment], cell + 1)
        else
          levels
        end
    end
  end

  @spec exists_level?(map(), non_neg_integer()) :: boolean()
  defp exists_level?(levels, level) do
    Map.has_key?(levels, level)
  end
end
