defmodule ADSWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  @moduledoc false

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-red-50 p-4 fixed top-1 right-1 w-96 fade-in-scale"
        phx-click={
          JS.push("lv:clear-flash")
          |> JS.remove_class("fade-in_scale", to: "#flash")
          |> hide("#flash")
        }
        phx-hook="Flash"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <.icon name={:check_circle} solid />
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-red-800">
              <%= live_flash(@flash, @kind) %>
            </p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100
                 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50
                 focus:ring-red-600"
              >
                <.icon name={:x} solid />
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale"
        phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in-scale") |> hide("#flash")}
        phx-value-key="info"
        phx-hook="Flash"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <.icon name={:check_circle} solid />
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-green-800">
              <%= live_flash(@flash, @kind) %>
            </p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500
                 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2
                 focus:ring-offset-green-50 focus:ring-green-600"
              >
                <.icon name={:x} solid />
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def icon(assigns) do
    assigns =
      assigns
      |> assign_new(:outlined, fn -> false end)
      |> assign_new(:class, fn -> "w-4 h-4 inline-block" end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% end %>
    """
  end
end
