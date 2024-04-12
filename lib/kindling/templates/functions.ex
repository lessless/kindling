defmodule Kindling.Templates.Functions do
  @moduledoc """
  Helper functions used the in generator templates.
  """

  @int_patterns [
    "^[1-9][0-9]*$",
    "^[0]|([1-9][0-9]*)$",
    "^-?([0]|([1-9][0-9]*))$",
    "^[0]|[-+]?[1-9][0-9]*$"
  ]

  @decimal_patterns [
    "^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?$",
    "^-?(0|[1-9][0-9]{0,17})(\\.[0-9]{1,17})?([eE][+-]?[0-9]{1,9}})?$"
  ]

  def enum_value_string(df) do
    df["enum"]
    |> Enum.map(&Recase.to_snake(&1))
    |> Enum.map(&String.to_atom/1)
    |> Enum.uniq()
    |> Enum.map_join(",\n", &inspect/1)
    |> then(&"[\n#{&1}\n]")
  end

  def fhir_type_to_ecto(%{"type" => "string"}), do: :string
  def fhir_type_to_ecto(%{"type" => "boolean"}), do: :boolean

  def fhir_type_to_ecto(%{"type" => "number", "pattern" => pattern})
      when pattern in @int_patterns,
      do: :integer

  def fhir_type_to_ecto(%{"type" => "number", "pattern" => pattern})
      when pattern in @decimal_patterns,
      do: :decimal

  def fhir_type_to_ecto(%{"$ref" => "#/definitions/boolean"}), do: :boolean
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/string"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/integer"}), do: :integer
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/positiveInt"}), do: :integer
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/unsignedInt"}), do: :integer
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/decimal"}), do: :decimal
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/code"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/uri"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/url"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/xhtml"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/markdown"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/base64Binary"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/integer64"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/date"}), do: :date
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/dateTime"}), do: :utc_datetime_usec
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/instant"}), do: :utc_datetime_usec
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/time"}), do: :time_usec
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/canonical"}), do: :string
  def fhir_type_to_ecto(%{"$ref" => "#/definitions/id"}), do: :binary_id

  def fhir_type_to_ecto(%{"type" => "array", "items" => %{"enum" => _}}), do: {:array, :string}

  def fhir_type_to_ecto(%{"type" => "array", "items" => items}),
    do: {:array, fhir_type_to_ecto(items)}
end
