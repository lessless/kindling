defmodule Kindling.Version do
  def version_dir(version),
    do: Path.join([Mix.Project.build_path(Mix.Project.config()), "fhir", version])
end
