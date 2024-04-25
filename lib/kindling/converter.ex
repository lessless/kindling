defmodule Kindling.Converter do
  @moduledoc """
  Convert between JSON-style maps and Elixir structs, using the generated resource Ecto schemas as
  a guide.
  """
  alias Kindling.Schema.Resource

  @doc """
  Convert a JSON-style map with string keys to a FHIR resource schema. `version_namespace` is
  the module namespace where your resource schema module have been generated (e.g. `FHIR.R4`)
  and `resource_json` is the map of data.
  """
  @spec convert(atom() | binary(), map()) :: Kindling.Schema.Resource.schema()
  def convert(version_namespace, %{"resourceType" => resource_type} = resource_json) do
    resource_module = Module.concat(version_namespace, Resource.class_name(resource_type))
    resource_list_module = Module.concat(version_namespace, "ResourceList")

    structify(resource_module, resource_list_module, resource_json)
  end

  @doc false
  def structify(
        resource_module,
        resource_list_module,
        %{"resourceType" => resource_type} = resource_json
      )
      when resource_module == resource_list_module do
    version_namespace =
      resource_module
      |> Module.split()
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> Module.concat()

    resource_module = Module.concat(version_namespace, Resource.class_name(resource_type))
    structify(resource_module, resource_list_module, resource_json)
  end

  def structify(resource_module, resource_list_module, resource_json) do
    Code.ensure_loaded!(resource_module)

    atom_map =
      resource_json
      |> map_or_nil(fn {key_string, value} ->
        key_atom = key_string |> Recase.to_snake() |> String.to_existing_atom()

        case value do
          nil ->
            {key_atom, nil}

          value ->
            {key_atom, convert_field(resource_module, resource_list_module, key_atom, value)}
        end
      end)
      |> case do
        nil ->
          nil

        enum ->
          Map.new(enum)
      end

    struct!(resource_module, atom_map)
  end

  @doc false
  def convert_field(resource_module, resource_list_module, field, value) do
    cond do
      field in resource_module.__schema__(:associations) ->
        convert_association(resource_module, resource_list_module, field, value)

      field in resource_module.__schema__(:embeds) ->
        convert_embed(resource_module, resource_list_module, field, value)

      field in resource_module.__schema__(:fields) ->
        cast_field(resource_module, field, value)

      true ->
        value
    end
  end

  @doc false
  def cast_field(resource_module, field, value) do
    type = resource_module.__schema__(:type, field)

    do_cast_field(type, value)
  end

  defp do_cast_field(:utc_datetime_usec, value) do
    case Kindling.Converter.DateTime.parse(value) do
      {:ok, v, _} ->
        v

      other ->
        other
    end
  end

  defp do_cast_field({:array, _} = type, value) do
    case Ecto.Type.cast(type, wrap(value)) do
      {:ok, v} ->
        v

      other ->
        other
    end
  end

  defp do_cast_field(type, value) do
    case Ecto.Type.cast(type, value) do
      {:ok, v} ->
        v

      other ->
        other
    end
  end

  @doc false
  def convert_association(resource_module, resource_list_module, field, value) do
    %{cardinality: cardinality, related: type} = resource_module.__schema__(:association, field)

    case cardinality do
      :many ->
        map_or_nil(wrap(value), &structify(type, resource_list_module, &1))

      :one ->
        structify(type, resource_list_module, value)
    end
  end

  @doc false
  def convert_embed(resource_module, resource_list_module, field, value) do
    %{cardinality: cardinality, related: type} = resource_module.__schema__(:embed, field)

    case cardinality do
      :many ->
        map_or_nil(wrap(value), &structify(type, resource_list_module, &1))

      :one ->
        structify(type, resource_list_module, value)
    end
  end

  defp map_or_nil(nil, _), do: nil

  defp map_or_nil(enum, mapper) do
    Enum.map(enum, mapper)
  end

  defp wrap(binary) when is_binary(binary), do: [binary]
  defp wrap(list) when is_list(list), do: list
  defp wrap(other), do: [other]
end
