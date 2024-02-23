defmodule Mix.Tasks.Kindling.GenerateSchemas do
  @moduledoc "Generates FHIR schemas"
  @shortdoc "Generates FHIR schemas"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    if Enum.count(args) != 3 do
      Mix.shell().error(
        "usage: mix mix kindling.generate_schemas <namespace> <R5|R4|R3> <root resource name>"
      )
    end

    [namespace, version, root] = args

    schema = Kindling.Schema.schema_object(version)
    to_generate = Kindling.Schema.refs_recursive(schema, root)

    Enum.each(
      to_generate,
      &Kindling.Templates.write_code(namespace, version, &1, schema["definitions"][&1])
    )
  end
end
