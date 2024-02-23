defmodule Kindling.Schema do
  alias Kindling.Version

  def schema_object(version) do
    filename = Path.join(Version.version_dir(version), "fhir.schema.json")

    filename
    |> File.read!()
    |> Jason.decode!()
  end
end
