defmodule Kindling.Schema.Resource do
  @empty_properties %{
    array: [],
    const: [],
    embeds_one: [],
    embeds_many: [],
    has_one: [],
    has_many: [],
    enum: [],
    value: []
  }

  def properties(df) do
    df["properties"]
  end

  def grouped_properties(df, roots) do
    properties =
      (df["properties"] || %{})
      |> Map.delete("id")
      |> Enum.reject(&is_element/1)
      |> Enum.map(fn {key, value} -> {key, value, property_type(value, roots)} end)
      |> Enum.group_by(fn {_key, _value, type} ->
        type
      end)

    Map.merge(@empty_properties, properties)
  end

  def all_fields(df) do
    (df["properties"] || %{})
    |> Enum.filter(fn {_name, definition} ->
      property_type(definition, []) in [:array, :enum, :value]
    end)
    |> Enum.map(fn {name, _} -> name end)
  end

  def required_fields(df) do
    df
    |> required()
    |> Enum.filter(fn {_name, definition} ->
      property_type(definition, []) in [:array, :enum, :value]
    end)
    |> Enum.map(fn {name, _} -> name end)
  end

  def required(df) do
    Map.take(df["properties"] || %{}, df["required"] || [])
  end

  def required?(df, key) do
    key in df["required"]
  end

  def property_type(%{"const" => _}, _roots), do: :const

  def property_type(%{"$ref" => "#/definitions/" <> name}, roots) do
    if is_class_name(name) do
      if name in roots do
        :has_one
      else
        :embeds_one
      end
    else
      :value
    end
  end

  def property_type(%{"items" => %{"$ref" => "#/definitions/" <> name}}, roots) do
    if is_class_name(name) do
      if name in roots do
        :has_many
      else
        :embeds_many
      end
    else
      :array
    end
  end

  def property_type(%{"items" => %{"enum" => _}}, _roots), do: :array
  def property_type(%{"enum" => _}, _roots), do: :enum
  def property_type(_, _roots), do: :value

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
    Regex.match?(~r/^[A-Z]/, name)
  end

  def is_element({_name, %{"$ref" => "#/definitions/Element"}}), do: true
  def is_element({name, %{"items" => items}}), do: is_element({name, items})
  def is_element(_), do: false

  def ref_to_class_name("#/definitions/" <> name),
    do: class_name(name)

  def class_name(name),
    do: name |> String.split("_") |> Enum.map(&Recase.to_pascal/1) |> Enum.join(".")
end
