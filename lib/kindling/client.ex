defmodule Kindling.Client do
  @moduledoc """
  FHIR API client.
  """
  alias Kindling.Converter

  defstruct [:base_url, :access_token, auth_mode: :bearer]

  @typedoc """
  Configuration of a FHIR client.
  """
  @type t :: %{
          base_url: fhir_server_base_url(),
          access_token: access_token(),
          auth_mode: :bearer | :basic | :open
        }
  @typedoc """
  The base URL of the FHIR server. Often (but not always), includes the FHIR version in the URL path.
  """
  @type fhir_server_base_url :: String.t()
  @typedoc """
  The FHIR access token. Used when :auth_mode is :bearer or :basic. Ignored when :auth_mode is :open.
  """
  @type access_token :: String.t()

  @typedoc """
  A string that is the ID of a FHIR resource.
  """
  @type resource_id :: String.t()

  @doc """
  Make a read REST request against a FHIR API server, for a resource of type `resource_module`
  and the id `id`. Returns a schema struct of the results, or an error.

  `opts`:
  - `headers`: additional HTTP request headers to send with the request, as a list of {key, value}
      pairs.
  """
  @spec read(t(), Kindling.Schema.Resource.t(), resource_id()) ::
          {:ok, Kindling.Schema.Resource.schema(), Keyword.t()} | term()
  def read(client, resource_module, id, opts \\ [], req_fn \\ &Kindling.Client.Req.get/2) do
    base_uri = URI.parse(client.base_url)
    uri = base_uri |> URI.append_path(resource_module.path()) |> URI.append_path("/#{id}")
    more_headers = Keyword.get(opts, :headers, [])

    headers = headers(client, more_headers)

    uri
    |> req_fn.(headers: headers)
    |> case do
      {:ok, %{status: status} = response} when status >= 200 and status < 300 ->
        Converter.convert(resource_module.version_namespace(), response.body)

      other ->
        other
    end
  end

  @doc """
  Make a search REST request against a FHIR API server, for a resource of type `resource_module`
  using the search params `params`.

  Returns a schema struct of the results (usually a FHIR bundle), or an error.

  `opts`:
  - `headers`: additional HTTP request headers to send with the request, as a list of {key, value}
      pairs.
  """
  @spec search(t(), Kindling.Schema.Resource.t(), Keyword.t(), Keyword.t()) ::
          {:ok, Kindling.Schema.Resource.schema()} | term()
  def search(
        client,
        resource_module,
        params \\ [],
        opts \\ [],
        req_fn \\ &Kindling.Client.Req.get/2
      ) do
    base_uri = URI.parse(client.base_url)
    query = URI.encode_query(params)
    uri = base_uri |> URI.append_path(resource_module.path()) |> URI.append_query(query)
    more_headers = Keyword.get(opts, :headers, [])

    headers = headers(client, more_headers)

    uri
    |> req_fn.(headers: headers)
    |> case do
      {:ok, %{status: status} = response} when status >= 200 and status < 300 ->
        Converter.convert(resource_module.version_namespace(), response.body)

      other ->
        other
    end
  end

  @doc false
  def headers(client, more_headers) do
    case client.auth_mode do
      :open ->
        [format_header() | more_headers]

      _other ->
        [auth_header(client) | [format_header() | more_headers]]
    end
  end

  @doc false
  def auth_header(%{auth_mode: :bearer, access_token: token}),
    do: {"Authorization", "Bearer #{token}"}

  def auth_header(%{auth_mode: :basic, access_token: token}),
    do: {"Authorization", "Basic #{token}"}

  @doc false
  def format_header do
    {"Accept", "application/json"}
  end
end
