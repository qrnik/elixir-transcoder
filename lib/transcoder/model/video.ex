defmodule Transcoder.Model.Video do
  use TranscoderWeb, :verified_routes
  alias __MODULE__

  defstruct [:upload, :extension, resolution: :original]

  def for_upload(path, filename) do
    upload_name = Path.basename(path)
    %Video{upload: upload_name, extension: extension(filename)}
  end

  def with_resolution(video, resolution) do
    %Video{upload: video.upload, extension: video.extension, resolution: resolution}
  end

  def original(video) do
    %Video{upload: video.upload, extension: video.extension, resolution: :original}
  end

  def path(video) do
    Path.join([:code.priv_dir(:transcoder), "static", "uploads", filename(video)])
  end

  def src(video), do: ~p"/uploads/#{filename(video)}"

  defp filename(video), do: "#{video.upload}_#{video.resolution}.#{video.extension}"

  defp extension(filename), do: Enum.at(String.split(filename, "."), 1)
end
