defmodule Kindling.SchemaDownloader do
  @moduledoc """
  Handles downloading and unzipping FHIR JSON schemas from the hl7 server.
  """

  @version_aliases %{
    "R3" => "STU3"
  }

  @doc """
  Download and unzip the JSON schema file for the given `version` into the _build directory for
  the library to reference.
  """
  @spec download_version(Kindling.Schema.version_string()) :: :ok | {:error, any()}
  def download_version(version) do
    {:ok, _} = Application.ensure_all_started(:req)
    version_alias = Map.get(@version_aliases, version, version)

    version_dir = "#{Mix.Project.build_path(Mix.Project.config())}/fhir/#{version}"
    filename = "#{version_dir}/fhir.schema.json.zip"
    File.mkdir_p!(version_dir)

    "http://hl7.org/fhir/#{version_alias}/fhir.schema.json.zip"
    |> Req.get!()
    |> then(&File.write!(filename, &1.body))

    case :zip.unzip(to_charlist(filename), cwd: to_charlist(version_dir)) do
      {:ok, _filelist} ->
        :ok

      other ->
        dbg(other)
        other
    end
  end

  @doc """
  Check if the `version` JSON schema is downloaded and unzipped for use. If not, download and unzip
  it. If that download & unzip fails, raise an error.
  """
  def ensure_version!(version) do
    version_dir = "#{Mix.Project.build_path(Mix.Project.config())}/fhir/#{version}"
    filename = "#{version_dir}/fhir.schema.json"

    cond do
      File.exists?(filename) ->
        :ok

      download_version(version) == :ok ->
        :ok

      true ->
        raise "Could not download and unzip the FHIR schema for version #{version}."
    end
  end
end
