Kindling is a library for working with [HL7 FHIR](https://hl7.org/fhir/) APIs. It can generate
each FHIR resource as an `Ecto.Schema`. It also contains a client for working with the FHIR REST
API.

## Installation

Kindling can be installed by adding `kindling` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kindling, "~> 1.0.1"}
  ]
end
```

You should then configure your root resources, which are the FHIR resources that your application
uses:

```elixir
config :kindling, root_resources: ["Bundle", "Patient", "Encounter"]
```

When you generate resource schemas, Kindling will generate these schemas, plus any that they reference (recursively).

## Generating Resource Schemas

[mix kindling.generate_schemas](`Mix.Tasks.Kindling.GenerateSchemas`) will generate Elixir source files for the resource schemas under a namespace module under the `lib/` directory. It takes two arguments: the name of the namespace module, and a FHIR version.

Example:

```sh
mix kindling.generate_schemas FHIR R4
```

## Example Schema Module

The generated schema modules are normal `Ecto.Schema`s. Here's an example of a Patient resource schema:

```elixir
defmodule FHIR.R4.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :active,
    :multiple_birth_boolean,
    :language,
    :implicit_rules,
    :birth_date,
    :multiple_birth_integer,
    :id,
    :deceased_boolean,
    :gender,
    :deceased_date_time
  ]
  @required_fields []

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "patient" do
    # Constants
    field(:resource_type, :string, virtual: true, default: "Patient")

    # Fields
    field(:active, :boolean)
    field(:multiple_birth_boolean, :boolean)
    field(:language, :string)
    field(:implicit_rules, :string)
    field(:birth_date, :date)
    field(:multiple_birth_integer, :integer)
    field(:deceased_boolean, :boolean)
    field(:deceased_date_time, :string)

    # Enum
    field(:gender, Ecto.Enum, values: [:male, :female, :other, :unknown])

    # Embed One
    embeds_one(:marital_status, FHIR.R4.CodeableConcept)
    embeds_one(:managing_organization, FHIR.R4.Reference)
    embeds_one(:text, FHIR.R4.Narrative)
    embeds_one(:meta, FHIR.R4.Meta)

    # Embed Many
    embeds_many(:photo, FHIR.R4.Attachment)
    embeds_many(:communication, FHIR.R4.Patient.Communication)
    embeds_many(:name, FHIR.R4.HumanName)
    embeds_many(:extension, FHIR.R4.Extension)
    embeds_many(:telecom, FHIR.R4.ContactPoint)
    embeds_many(:contained, FHIR.R4.ResourceList)
    embeds_many(:link, FHIR.R4.Patient.Link)
    embeds_many(:contact, FHIR.R4.Patient.Contact)
    embeds_many(:modifier_extension, FHIR.R4.Extension)
    embeds_many(:identifier, FHIR.R4.Identifier)
    embeds_many(:general_practitioner, FHIR.R4.Reference)
    embeds_many(:address, FHIR.R4.Address)
  end

  def version, do: FHIR.R4
  def path, do: "/Patient"

  def base_changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
```

## API Client

Kindling also includes a [FHIR REST API client](`Kindling.Client`) that can be used to request resources
from a FHIR server. The client will automatically convert the results to resource schema structs:

```elixir
# Use the public FHIR test server
client = %{
  base_url: "http://hapi.fhir.org/baseR4",
  auth_mode: :open
}

patient_id = "593166"

Kindling.Client.read(client, FHIR.R4.Patient, patient_id)
```

Results in a struct something like this:

```elixir
%FHIR.R4.Patient{
  __meta__: #Ecto.Schema.Metadata<:built, "patient">,
  id: "593166",
  resource_type: "Patient",
  active: nil,
  multiple_birth_boolean: nil,
  language: nil,
  implicit_rules: nil,
  birth_date: ~D[2000-10-31],
  multiple_birth_integer: nil,
  deceased_boolean: nil,
  deceased_date_time: nil,
  gender: :female,
  marital_status: nil,
  managing_organization: nil,
  text: %FHIR.R4.Narrative{
    id: nil,
    div: "<div xmlns=\"http://www.w3.org/1999/xhtml\"><div class=\"hapiHeaderText\">Sabrina <b>SPELLMAN </b></div><table class=\"hapiPropertyTable\"><tbody/></table></div>",
    status: :generated,
    extension: []
  },
  meta: %FHIR.R4.Meta{
    id: nil,
    last_updated: {:error, :invalid_format},
    source: "#NPQrzINFNuDwuDgM",
    version_id: "1",
    profile: nil,
    extension: [],
    security: [],
    tag: []
  },
  photo: [],
  communication: [],
  name: [
    %FHIR.R4.HumanName{
      id: nil,
      family: "Spellman",
      text: nil,
      given: ["Sabrina"],
      prefix: nil,
      suffix: nil,
      use: nil,
      period: nil,
      extension: []
    }
  ],
  extension: [],
  telecom: [
    %FHIR.R4.ContactPoint{
      id: nil,
      rank: nil,
      value: "1(845)443-7666",
      system: :phone,
      use: :home,
      period: nil,
      extension: []
    }
  ],
  contained: [],
  link: [],
  contact: [],
  modifier_extension: [],
  identifier: [],
  general_practitioner: [],
  address: [
    %FHIR.R4.Address{
      id: nil,
      city: "Greendale",
      country: "United States",
      district: nil,
      postal_code: "11199",
      state: "New York",
      text: nil,
      line: ["1138 Decario Lane"],
      type: nil,
      use: nil,
      period: nil,
      extension: []
    }
  ]
}
```

## Additional Resources

The docs can be found at <https://hexdocs.pm/kindling>.
