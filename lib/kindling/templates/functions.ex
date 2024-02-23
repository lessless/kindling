defmodule Kindling.Templates.Functions do
  @int_patterns [
    "^[1-9][0-9]*$",
    "^[0]|([1-9][0-9]*)$",
    "^-?([0]|([1-9][0-9]*))$"
  ]

  @decimal_patterns ["^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?$"]

  def fhir_type_to_ecto(%{"type" => "string"}), do: :string
  def fhir_type_to_ecto(%{"type" => "boolean"}), do: :boolean

  def fhir_type_to_ecto(%{"type" => "number", "pattern" => pattern})
      when pattern in @int_patterns,
      do: :integer

  def fhir_type_to_ecto(%{"type" => "number", "pattern" => pattern})
      when pattern in @decimal_patterns,
      do: :decimal

  def fhir_type_to_ecto(%{"type" => "array", "items" => %{"enum" => _}}), do: {:array, :string}

  def ref_to_class_name("#/definitions/" <> name),
    do: name |> String.replace("_", ".") |> Recase.to_pascal()
end
