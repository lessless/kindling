defmodule Kindling.Schema do
  @moduledoc """
  Tools for working with the JSON schema for FHIR.
  """

  alias Kindling.Schema.Resource
  alias Kindling.Version

  @typedoc """
  A string representing a particular FHIR version ("R5" | "R4B" | "R4" | "R3" ).
  """
  @type version_string :: String.t()

  @doc """
  Load and process a JSON schema file for the given `version`, return the map defining the spec
  for that version.
  """
  @spec schema_map(version_string()) :: map()
  def schema_map(version) do
    filename = Path.join(Version.version_dir(version), "fhir.schema.json")
    choices = get_choice_data(version)

    filename
    |> File.read!()
    |> Jason.decode!()
    |> build_backlinks()
    |> add_choice_data(choices)
  end

  def get_choice_data(version) do
    filename = Path.join(Version.version_dir(version), "choice-elements.json")

    filename
    |> File.read!()
    |> Jason.decode!()
  end

  def all_resources(schema) do
    schema
    |> get_in(["discriminator", "mapping"])
    |> Map.keys()
  end

  @doc false
  def build_backlinks(schema) do
    new_defs =
      schema["definitions"]
      |> Enum.map(fn {name, def} -> {name, Map.put(def, "__backlinks", [])} end)
      |> Map.new()

    schema =
      Map.put(schema, "definitions", new_defs)

    defs =
      schema["definitions"]
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

  def add_choice_data(schema, %{"elements" => choices}) do
    Enum.reduce(choices, schema, &apply_choice/2)
  end

  defp apply_choice({path, types_list}, schema) do
    [type_name | rest] = String.split(path, ".")

    {type_name, field_name} = follow_refs(schema, type_name, rest)
    field_name = String.replace(field_name, "[x]", "")
    type = schema["definitions"][type_name]

    types_list =
      case types_list do
        ["*"] ->
          type["properties"]
          |> Map.keys()
          |> Enum.filter(&String.starts_with?(&1, field_name))
          |> Enum.map(&String.replace(&1, field_name, ""))

        other ->
          other
      end

    field_names =
      Enum.map(types_list, fn type ->
        "#{field_name}_#{Recase.to_snake(type)}"
      end)

    existing_choices = Map.get(type, "__choices", %{})
    new_choices = Map.put(existing_choices, field_name, field_names)

    put_in(schema, ["definitions", type_name, "__choices"], new_choices)
  end

  defp follow_refs(_schema, type_name, [field_name]), do: {type_name, field_name}

  defp follow_refs(schema, type_name, [hd | rest]) do
    ref =
      case schema["definitions"][type_name]["properties"][hd] do
        %{"items" => %{"$ref" => ref}} ->
          ref

        %{"$ref" => ref} ->
          ref
      end

    "#/definitions/" <> next_type = ref

    follow_refs(schema, next_type, rest)
  end

  @doc """
  Given a schema map in the style returned by `&schema_map/1`, and a root resource name (e.g.
  `"Encounter"`), return a `MapSet` of resources that are referenced (recursively) from the
  resource. This can be used to determine the set of resource schemas that need to be generated
  to full support that resource as a fully-defined set or schemas.
  """
  @spec refs_recursive(map(), String.t()) :: MapSet.t()
  def refs_recursive(schema, root_name) when is_binary(root_name) do
    do_recurse(schema, MapSet.new([root_name]), [root_name])
  end

  def refs_recursive(schema, roots) when is_list(roots) do
    do_recurse(schema, MapSet.new(roots), roots)
  end

  defp do_recurse(_schema, visited, []), do: visited

  defp do_recurse(schema, visited, [hd | tail]) do
    refs = Resource.refs(schema["definitions"][hd])
    new_refs = MapSet.difference(refs, visited)
    new_visited = MapSet.union(visited, refs)
    do_recurse(schema, new_visited, MapSet.to_list(new_refs) ++ tail)
  end
end
