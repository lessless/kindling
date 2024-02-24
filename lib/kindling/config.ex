defmodule Kindling.Config do
  @default_embedded_resources [
    "Coding",
    "Duration",
    "Extension",
    "Identifier",
    "Meta",
    "Element",
    "CodeableConcept",
    "Narrative",
    "Period",
    "Reference",
    "ResourceList"
  ]

  def embedded_resources() do
    Application.get_env(:kindling, :embedded_resources, @default_embedded_resources)
  end
end
