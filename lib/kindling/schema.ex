defmodule Kindling.Schema do
  alias Kindling.Version
  alias Kindling.Schema.Resource

  def schema_object(version) do
    filename = Path.join(Version.version_dir(version), "fhir.schema.json")

    filename
    |> File.read!()
    |> Jason.decode!()
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
