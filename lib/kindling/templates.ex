defmodule Kindling.Templates do
  @moduledoc """
  Template functions for generating FHIR Resource modules.
  """

  require EEx

  import Kindling.Templates.Functions
  import Kindling.Schema.Resource

  alias Kindling.Schema.Resource

  EEx.function_from_file(:def, :render, "lib/kindling/template.eex", [:assigns])
  EEx.function_from_file(:def, :render_embedded, "lib/kindling/embed_template.eex", [:assigns])

  def resource_code(namespace, version, roots, resource_name, resource) do
    assigns = %{
      namespace: namespace,
      version: version,
      resource_name: resource_name,
      properties: Resource.grouped_properties(resource, roots),
      all_fields: Resource.all_fields(resource),
      required_fields: Resource.required_fields(resource),
      backlinks: Enum.filter(resource["__backlinks"], &(&1 in roots)),
      choices: resource["__choices"] || %{}
    }

    if resource_name in roots do
      assigns
      |> render()
      |> Code.format_string!(file: "#{resource_name}.ex")
    else
      assigns
      |> render_embedded()
      |> Code.format_string!(file: "#{resource_name}.ex")
    end
  end

  def write_code(namespace, version, roots, resource_name, resource) do
    dir = Path.join(["lib", String.downcase(namespace), String.downcase(version)])
    file = Path.join([dir | to_source_file_name(resource_name)])

    File.mkdir_p!(Path.dirname(file))
    File.write!(file, resource_code(namespace, version, roots, resource_name, resource))
  end

  def to_source_file_name(resource_name) do
    resource_name
    |> String.split("_")
    |> Enum.reverse()
    |> Enum.map(&Recase.to_snake/1)
    |> then(fn [hd | tail] -> ["#{hd}.ex" | tail] end)
    |> Enum.reverse()
  end
end
