defmodule Kindling.Schema do
  alias Kindling.Config
  alias Kindling.Version
  alias Kindling.Schema.Resource

  def schema_object(version) do
    filename = Path.join(Version.version_dir(version), "fhir.schema.json")

    filename
    |> File.read!()
    |> Jason.decode!()
    |> build_backlinks()
  end

  def build_backlinks(schema) do
    new_defs =
      schema["definitions"]
      |> Enum.map(fn {name, def} -> {name, Map.put(def, "__backlinks", [])} end)
      |> Map.new()

    schema =
      Map.put(schema, "definitions", new_defs)

    defs =
      schema["definitions"]
      |> Map.drop(Config.embedded_resources())
      |> Enum.reduce(schema["definitions"], fn {name, df}, definitions ->
        refs = Resource.refs(df)

        Enum.reduce(refs, definitions, fn ref, definitions ->
          prior_backlinks = definitions[ref]["__backlinks"]
          new_backlinks = [name | prior_backlinks]
          new_def = Map.put(Map.get(definitions, ref), "__backlinks", new_backlinks)
          Map.put(definitions, ref, new_def)
        end)
      end)

    Map.put(schema, "definitions", defs)
  end

  def refs_recursive(schema, root_name) do
    do_recurse(schema, MapSet.new([root_name]), [root_name])
  end

  defp do_recurse(_schema, visited, []), do: visited

  defp do_recurse(schema, visited, [hd | tail]) do
    refs = Resource.refs(schema["definitions"][hd])
    new_refs = MapSet.difference(refs, visited)
    new_visited = MapSet.union(visited, refs)
    do_recurse(schema, new_visited, MapSet.to_list(new_refs) ++ tail)
  end
end
