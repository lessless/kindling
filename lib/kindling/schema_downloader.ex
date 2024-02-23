defmodule Kindling.SchemaDownloader do
  def download_version(version) do
    version_dir = "#{Mix.Project.build_path(Mix.Project.config())}/fhir/#{version}"
    filename = "#{version_dir}/fhir.schema.json.zip"
    File.mkdir_p!(version_dir)

    "http://hl7.org/fhir/#{version}/fhir.schema.json.zip"
    |> Req.get!()
    |> then(&File.write!(filename, &1.body))

    case :zip.unzip(to_charlist(filename), cwd: to_charlist(version_dir)) do
      {:ok, _filelist} ->
        :ok

      other ->
        other
    end
  end
end
