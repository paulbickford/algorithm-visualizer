defmodule ADSWeb.AlgorithmsLive do
  use ADSWeb, :live_view
  use TypeCheck

  alias ADS.{Helpers, InsertionSort, MergeSort, Step}

  @moduledoc false

  def render(assigns) do
    ~H"""
    <div class="w-full h-full bg-gray-50">
      <header class="fixed flex items-center top-0 w-full h-20 py-2 border-b-2 border-gray-300 bg-gray-800">
        <h1 class=" w-full text-l md:text-2xl text-center align-middle text-gray-100">
          Algorithms and Data Structures
        </h1>
      </header>

      <div class="fixed top-20 bottom-0 w-full flex justify-start flex-row overflow-auto">
        <input type="checkbox" class="sidebar-checkbox hidden" id="sidebar-toggle" />
        <label for="sidebar-toggle" class="sidebar-button md:hidden">
          <div class="fixed top-5 left-0 sidebar-icon h-9 w-9 text-center z-40 cursor-pointer">
            <div class="sidebar-icon-top absolute mt-[7px] ml-1.5 w-7 h-[3px] bg-gray-500 transition-all">
            </div>
            <div class="sidebar-icon-middle absolute mt-[18px] ml-1.5 w-7 h-[3px] bg-gray-500"></div>
            <div class="sidebar-icon-bottom absolute mt-[29px] ml-1.5 w-7 h-[3px] bg-gray-500 transition-all">
            </div>
          </div>
        </label>

        <div class="sidebar fixed md:relative top-20 md:top-0 w-0 md:min-w-fit h-full
      md:p-2 truncate bg-[#bfcbee] transition-all z-40">
          <.display_radio algorithm={@algorithm} />
        </div>

        <div class="relative h-full basis-full py-8 md:py-20">
          <div class="flex flex-row md:flex-col my-auto gap-2">
            <%= for {level_index, level} <- @levels do %>
              <.display_level
                hide_segments?={@hide_segments?}
                level={level}
                level_index={level_index}
                level_populated?={Enum.member?(@levels_populated, level_index)}
                values={@values}
              />
            <% end %>
          </div>

          <button
            class={
              "absolute transition-all duration-1000 cursor-pointer
              h-10 px-4 rounded-md border-1 border-slate-200 shadow-md z-20 bg-[#8efaf3]
              #{move_button_down(@ready?)}"
            }
            phx-click="start"
          >
            Start
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp display_cell(assigns) do
    ~H"""
    <div class={
      "md:inline-block md:mx-1 my-1 md:my-auto transition-all
      #{get_cell_style(@style)} #{get_level_style(:cell, @level_populated?)}"
    }>
      <span class="align-top text-xs text-blue-400">
        <%= nil %>
      </span>
      <span class="inline-block text-center text-lg w-full text-gray-800">
        <%= @value %>
      </span>
    </div>
    """
  end

  defp display_level(assigns) when map_size(assigns) == 0 do
    nil
  end

  defp display_level(assigns) do
    ~H"""
    <div class={
      "flex flex-col md:flex-row gap-2 my-auto md:mx-auto transition-all
      #{get_level_style(:level, @level_populated?)}"
    }>
      <%= for {i, len} <- @level do %>
        <.display_segment
          hide_segments?={@hide_segments?}
          length={len}
          level_index={@level_index}
          level_populated?={@level_populated?}
          segment_index={i}
          values={@values}
        />
      <% end %>
    </div>
    """
  end

  defp display_radio(assigns) do
    ~H"""
    <div class="pl-3 text-gray-700 w-40">
      <h1 class="text-lg">Algorithms</h1>
      <div class="pl-2 text">
        <div
          class={"cursor-pointer hover:text-lg #{get_mode_text("insertion_sort", @algorithm)}"}
          phx-value-algorithm="insertion_sort"
          phx-click="algorithm"
        >
          Insertion Sort
        </div>
        <div
          class={"cursor-pointer hover:text-lg #{get_mode_text("merge_sort", @algorithm)}"}
          phx-value-algorithm="merge_sort"
          phx-click="algorithm"
        >
          Merge Sort
        </div>
      </div>
    </div>
    """
  end

  defp display_segment(assigns) do
    ~H"""
    <div class={
        "md:inline-block mx-2 md:my-2 p-2 md:whitespace-nowrap transition-all
        #{@hide_segments? || "bg-gray-100"} #{get_level_style(:segment, @level_populated?)}"
      }>
      <%= for i <- 0..@length - 1 do %>
        <.display_cell
          cell_index={i}
          level_index={@level_index}
          level_populated?={@level_populated?}
          segment_index={@segment_index}
          style={get_in(@values, [{@level_index, @segment_index, i}, :style])}
          value={get_in(@values, [{@level_index, @segment_index, i}, :value])}
        />
      <% end %>
    </div>
    """
  end

  @spec get_algorithm_module(String.t()) :: atom()
  defp get_algorithm_module(algorithm) do
    Map.get(
      %{"insertion_sort" => :"Elixir.ADS.InsertionSort", "merge_sort" => :"Elixir.ADS.MergeSort"},
      algorithm,
      :"Elixir.ADS.InsertionSort"
    )
  end

  @spec get_cell_style(atom()) :: String.t()
  defp get_cell_style(type) do
    case type do
      :sorted ->
        "bg-blue-100"

      nil ->
        nil
    end
  end

  @spec get_interval() :: non_neg_integer()
  defp get_interval() do
    300
  end

  @spec get_list_length() :: non_neg_integer()
  defp get_list_length() do
    8
  end

  @spec get_mode_text(String.t(), String.t()) :: String.t()
  defp get_mode_text(label_algorithm, selected_algorithm) do
    case label_algorithm == selected_algorithm do
      true -> "text-gray-600"
      false -> ""
    end
  end

  @spec get_level_style(atom(), boolean()) :: String.t()
  defp get_level_style(type, populated?) do
    case {type, populated?} do
      {:cell, true} ->
        "h-8 w-12"

      {:cell, false} ->
        "h-8 md:h-2 w-2 md:w-12"

      {:level, true} ->
        "md:h-12 w-16 md:w-auto"

      {:level, false} ->
        "md:h-6 w-6 md:w-auto"

      {:segment, true} ->
        "md:h-12 w-16 md:w-auto"

      {:segment, false} ->
        "md:h-4 w-4 md:w-auto"

      _ ->
        ""
    end
  end

  @spec move_button_down(boolean()) :: String.t()
  defp move_button_down(ready?) do
    case ready? do
      true ->
        # "inset-1/3 opacity-30 pointer-events-none"
        "bottom-10 left-10 opacity-30 pointer-events-none"

      false ->
        # "inset-1/2 opacity-100 pointer-events-auto"
        "bottom-2/4 left-2/4 opacity-100 pointer-events-auto"
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       algorithm: "insertion_sort",
       hide_segments?: false,
       levels: %{},
       levels_populated: [0],
       ready?: false,
       values: %{}
     )}
  end

  def handle_event("algorithm", %{"algorithm" => algorithm}, socket) do
    IO.puts(algorithm)
    {:noreply, assign(socket, algorithm: algorithm)}
  end

  def handle_event("start", _value, %{assigns: %{algorithm: algorithm}} = socket) do
    input = Helpers.random_list(100, true, get_list_length())
    {_output, steps} = get_algorithm_module(algorithm).generate_steps(input)
    send(self(), {:tick, steps})
    {:noreply, assign(socket, hide_segments?: false)}
  end

  def handle_info({:add_levels, levels}, socket) do
    {:noreply, assign(socket, levels: levels)}
  end

  def handle_info({:add_values, values}, socket) do
    {:noreply, assign(socket, values: values)}
  end

  def handle_info({:finish}, socket) do
    {:noreply, assign(socket, ready?: false)}
  end

  def handle_info({:hide_segments}, socket) do
    {:noreply, assign(socket, hide_segments?: true)}
  end

  def handle_info({:compare, {_cell1, _cell2, _comparator}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:mark_selected, cell}, %{assigns: %{values: values}} = socket) do
    values = put_in(values[cell][:style], :selected)
    {:noreply, assign(socket, values: values)}
  end

  def handle_info({:mark_sorted, cell}, %{assigns: %{values: values}} = socket) do
    values = put_in(values[cell][:style], :sorted)
    {:noreply, assign(socket, values: values)}
  end

  def handle_info(
        {:move_value, {from_level, from_segment, from_cell}, {to_level, to_segment, to_cell}},
        %{assigns: %{values: values}} = socket
      ) do
    values =
      values
      |> Map.put(
        {to_level, to_segment, to_cell},
        Map.get(values, {from_level, from_segment, from_cell})
      )
      |> Map.drop([{from_level, from_segment, from_cell}])

    levels_populated = get_populated_levels(values)

    {:noreply, assign(socket, levels_populated: levels_populated, values: values)}
  end

  def handle_info(
        {:move_values, {from_level, from_segment, from_cells}, {to_level, to_segment, to_cells}},
        %{assigns: %{values: values}} = socket
      ) do
    cell_indices = Enum.zip(from_cells, to_cells)

    moved_values =
      for {from, to} <- cell_indices, into: %{} do
        {{to_level, to_segment, to}, Map.get(values, {from_level, from_segment, from})}
      end

    keys_to_drop = Enum.map(from_cells, &{from_level, from_segment, &1})

    values =
      values
      |> Map.merge(moved_values)
      |> Map.drop(keys_to_drop)

    levels_populated = get_populated_levels(values)

    {:noreply, assign(socket, levels_populated: levels_populated, values: values)}
  end

  def handle_info({:tick, steps}, %{assigns: %{ready?: ready?}} = socket) do
    case Step.next_step(steps) do
      :empty ->
        Process.send_after(self(), {:tick, steps}, get_interval())
        {:noreply, socket}

      {:finish} ->
        send(self(), {:finish})
        {:noreply, socket}

      {:start} ->
        Process.send_after(self(), {:tick, steps}, get_interval())
        {:noreply, assign(socket, ready?: true)}

      step ->
        if ready? do
          send(self(), step)
          Process.send_after(self(), {:tick, steps}, get_interval())
          {:noreply, socket}
        end
    end
  end

  @spec get_populated_levels(map()) :: list()
  defp get_populated_levels(values) do
    for {{level, _seg, _cell}, val} <- values, val != nil, :uniq do
      level
    end
  end
end
