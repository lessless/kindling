defmodule Kindling.Version do
  @moduledoc """
  Functions for working with FHIR versions e.g. R3, R4, R5, STU3, etc.
  """

  def version_dir(version),
    do: Path.join([Mix.Project.build_path(Mix.Project.config()), "fhir", version])
end
