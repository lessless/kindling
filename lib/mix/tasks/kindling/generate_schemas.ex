defmodule Mix.Tasks.Kindling.GenerateSchemas do
  @moduledoc "Generates FHIR schemas"
  @shortdoc "Generates FHIR schemas"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    if Enum.count(args) != 2 do
      Mix.shell().error("usage: mix mix kindling.generate_schemas <namespace> <R5|R4|R3>")

      raise "Argument error."
    end

    [namespace, version] = args

    Kindling.SchemaDownloader.ensure_version!(version)
    Kindling.SchemaDownloader.ensure_choices!(version)

    schema = Kindling.Schema.schema_map(version)
    roots = Kindling.Config.root_resources()

    to_generate =
      Kindling.Schema.refs_recursive(schema, roots)

    Enum.each(
      to_generate,
      &Kindling.Templates.write_code(namespace, version, roots, &1, schema["definitions"][&1])
    )
  end
end
