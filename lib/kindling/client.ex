defmodule Kindling.Client do
  alias Kindling.Converter

  defstruct [:base_url, :access_token, auth_mode: :bearer]

  def read(client, resource_module, id, opts \\ []) do
    base_uri = URI.parse(client.base_url)
    uri = base_uri |> URI.append_path(resource_module.path()) |> URI.append_path("/#{id}")
    more_headers = Keyword.get(opts, :headers, [])

    headers = headers(client, more_headers)

    uri
    |> Req.get(headers: headers)
    |> case do
      {:ok, %{status: status} = response} when status >= 200 and status < 300 ->
        Converter.convert(resource_module.version(), response.body)

      other ->
        other
    end
  end

  def search(client, resource_module, params \\ [], opts \\ []) do
    base_uri = URI.parse(client.base_url)
    query = URI.encode_query(params)
    uri = base_uri |> URI.append_path(resource_module.path()) |> URI.append_query(query)
    more_headers = Keyword.get(opts, :headers, [])

    headers = headers(client, more_headers)

    uri
    |> Req.get(headers: headers)
    |> case do
      {:ok, %{status: status} = response} when status >= 200 and status < 300 ->
        Converter.convert(resource_module.version(), response.body)

      other ->
        other
    end
  end

  def headers(client, more_headers) do
    case client.auth_mode do
      :open ->
        [format_header() | more_headers]

      _other ->
        [auth_header(client) | [format_header() | more_headers]]
    end
  end

  def auth_header(%{auth_mode: :bearer, access_token: token}),
    do: {"Authorization", "Bearer #{token}"}

  def auth_header(%{auth_mode: :basic, access_token: token}),
    do: {"Authorization", "Basic #{token}"}

  def format_header do
    {"Accept", "application/json"}
  end
end
