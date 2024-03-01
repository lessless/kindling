defmodule Kindling.Config do
  def root_resources, do: Application.get_env(:kindling, :root_resources, ["Encounter"])
end
