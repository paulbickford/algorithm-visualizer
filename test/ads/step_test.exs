defmodule ADS.StepTest do
  use ExUnit.Case

  @moduledoc false

  describe "add_values/2" do
    test "enqueues a step to add list of values" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.add_values(pid, %{0 => 0, 1 => 1, 2 => 2})

      assert {:add_values,
              %{
                {0, 0, 0} => %{style: nil, value: 0},
                {0, 0, 1} => %{style: nil, value: 1},
                {0, 0, 2} => %{style: nil, value: 2}
              }} = ADS.Step.next_step(pid)
    end
  end

  describe "compare/4" do
    test "enqueues a step to compare values of cell1 to cell2" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.compare(pid, 2, 3, :gt)
      assert {:compare, {2, 3, :gt}} = ADS.Step.next_step(pid)
    end
  end

  describe "finish/1" do
    test "enqueues a step to signal the finish of the procedure" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.finish(pid)
      assert {:start} = ADS.Step.next_step(pid)
      assert {:add_levels, %{0 => %{0 => 0}}} = ADS.Step.next_step(pid)
      assert {:finish} = ADS.Step.next_step(pid)
    end
  end

  describe "mark_selected/2" do
    test "enqueues a step to mark given cell as selected" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.mark_selected(pid, 1)
      assert {:mark_selected, 1} = ADS.Step.next_step(pid)
    end
  end

  describe "mark_sorted/2" do
    test "enqueues a step to mark given cell as sorted" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.mark_sorted(pid, 1)
      assert {:mark_sorted, 1} = ADS.Step.next_step(pid)
    end
  end

  describe "move_value/3" do
    test "enqueues a step to move value from cell1 to cell2" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.move_value(pid, {0, 0, 0}, {0, 0, 1})
      assert {:move_value, {0, 0, 0}, {0, 0, 1}} = ADS.Step.next_step(pid)
    end
  end

  describe "remove_temp_cell/1" do
    test "enqueues a step to remove given cell" do
      pid = start_supervised!(ADS.Step)
      ADS.Step.remove_temp_cell(pid)
      assert {:remove_temp_cell} = ADS.Step.next_step(pid)
    end
  end
end
