defmodule Kindling.Templates do
  require EEx

  import Kindling.Templates.Functions

  alias Kindling.Schema.Resource

  EEx.function_from_file(:def, :render, "lib/kindling/template.eex", [:assigns])

  def resource_code(namespace, version, resource_name, resource) do
    assigns = %{
      namespace: namespace,
      version: version,
      resource_name: resource_name,
      properties: Resource.grouped_properties(resource)
    }

    assigns |> render() |> Code.format_string!(file: "#{resource_name}.ex")
  end

  def write_code(namespace, version, resource_name, resource) do
    dir = Path.join(String.downcase(namespace), String.downcase(version))
    file = Path.join(dir, "#{Recase.to_snake(resource_name)}.ex")

    File.mkdir_p!(dir)
    File.write!(file, resource_code(namespace, version, resource_name, resource))
  end
end
