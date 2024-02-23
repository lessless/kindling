defmodule Kindling.Schema.Resource do
  @empty_properties %{array: [], const: [], has_one: [], has_many: [], enum: [], value: []}

  def properties(df) do
    df["properties"]
  end

  def grouped_properties(df) do
    properties =
      (df["properties"] || %{})
      |> Enum.map(fn {key, value} -> {key, value, property_type(value)} end)
      |> Enum.group_by(fn {_key, _value, type} ->
        type
      end)

    Map.merge(@empty_properties, properties)
  end

  def all_fields(df) do
    (df["properties"] || %{})
    |> Enum.filter(fn {_name, definition} ->
      property_type(definition) in [:array, :enum, :value]
    end)
    |> Enum.map(fn {name, _} -> name end)
  end

  def required_fields(df) do
    df
    |> required()
    |> Enum.filter(fn {_name, definition} ->
      property_type(definition) in [:array, :enum, :value]
    end)
    |> Enum.map(fn {name, _} -> name end)
  end

  def required(df) do
    Map.take(df["properties"] || %{}, df["required"] || [])
  end

  def required?(df, key) do
    key in df["required"]
  end

  def property_type(%{"const" => _}), do: :const
  def property_type(%{"$ref" => _}), do: :has_one
  def property_type(%{"items" => %{"$ref" => _}}), do: :has_many
  def property_type(%{"items" => %{"enum" => _}}), do: :array
  def property_type(%{"enum" => _}), do: :enum
  def property_type(_), do: :value

  def refs(df) do
    (df["properties"] || %{})
    |> Enum.map(fn
      {_, %{"$ref" => "#/definitions/" <> name}} ->
        name

      {_, %{"items" => %{"$ref" => "#/definitions/" <> name}}} ->
        name

      _other ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end
end
