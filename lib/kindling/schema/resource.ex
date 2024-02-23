defmodule Kindling.Schema.Resource do
  @empty_properties %{const: [], has_one: [], has_many: [], enum: [], value: []}

  def properties(df) do
    df["properties"]
  end

  def grouped_properties(df) do
    properties =
      (df["properties"] || [])
      |> Enum.map(fn {key, value} -> {key, value, property_type(value)} end)
      |> Enum.group_by(fn {_key, _value, type} ->
        type
      end)

    Map.merge(@empty_properties, properties)
  end

  def required(df) do
    Map.take(df["properties"], df["required"])
  end

  def required?(df, key) do
    key in df["required"]
  end

  def property_type(%{"const" => _}), do: :const
  def property_type(%{"$ref" => _}), do: :has_one
  def property_type(%{"items" => _}), do: :has_many
  def property_type(%{"enum" => _}), do: :enum
  def property_type(_), do: :value
end
