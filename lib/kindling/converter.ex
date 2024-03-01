defmodule Kindling.Converter do
  alias Kindling.Schema.Resource

  def convert(version_namespace, %{"resourceType" => resource_type} = resource_json) do
    resource_module = Module.concat(version_namespace, Resource.class_name(resource_type))
    resource_list_module = Module.concat(version_namespace, "ResourceList")

    structify(resource_module, resource_list_module, resource_json)
  end

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
      |> Enum.map(fn {key_string, value} ->
        key_atom = key_string |> Recase.to_snake() |> String.to_existing_atom()
        {key_atom, convert_field(resource_module, resource_list_module, key_atom, value)}
      end)
      |> Map.new()

    struct!(resource_module, atom_map)
  end

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

  defp do_cast_field(type, value) do
    case Ecto.Type.cast(type, value) do
      {:ok, v} ->
        v

      other ->
        other
    end
  end

  def convert_association(resource_module, resource_list_module, field, value) do
    %{cardinality: cardinality, related: type} = resource_module.__schema__(:association, field)

    case cardinality do
      :many ->
        Enum.map(value, &structify(type, resource_list_module, &1))

      :one ->
        structify(type, resource_list_module, value)
    end
  end

  def convert_embed(resource_module, resource_list_module, field, value) do
    %{cardinality: cardinality, related: type} = resource_module.__schema__(:embed, field)

    case cardinality do
      :many ->
        Enum.map(value, &structify(type, resource_list_module, &1))

      :one ->
        structify(type, resource_list_module, value)
    end
  end
end
