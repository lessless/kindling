defmodule Kindling.Config do
  @moduledoc """
  Configuration for Kindling.
  """

  @doc """
  Returns the list of configured root resources.
  """
  @spec root_resources() :: [String.t()]
  def root_resources,
    do: Application.get_env(:kindling, :root_resources, ["Bundle", "Patient", "Encounter"])
end
