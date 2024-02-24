defmodule Kindling.Schema.Resource do
  alias Kindling.Config

  @empty_properties %{array: [], const: [], has_one: [], has_many: [], enum: [], value: []}

  def properties(df) do
    df["properties"]
  end

  def grouped_properties(df) do
    properties =
      (df["properties"] || %{})
      |> Map.delete("id")
      |> Enum.reject(&is_element/1)
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

  for embed <- Config.embedded_resources() do
    dbg(embed)

    def property_type(%{"$ref" => "#/definitions/" <> unquote(embed)}), do: :embed_one

    def property_type(%{"items" => %{"$ref" => "#/definitions/" <> unquote(embed)}}) do
      :embed_many
    end
  end

  def property_type(%{"$ref" => "#/definitions/" <> name}) do
    if is_class_name(name) do
      :has_one
    else
      :value
    end
  end

  def property_type(%{"items" => %{"$ref" => "#/definitions/" <> name}}) do
    if is_class_name(name) do
      :has_many
    else
      :array
    end
  end

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
    |> Enum.filter(&is_class_name/1)
    |> MapSet.new()
  end

  def is_class_name(name) do
    !(name in Config.embedded_resources()) && Regex.match?(~r/^[A-Z]/, name)
  end

  def is_element({_name, %{"$ref" => "#/definitions/Element"}}), do: true
  def is_element({name, %{"items" => items}}), do: is_element({name, items})
  def is_element(_), do: false
end
