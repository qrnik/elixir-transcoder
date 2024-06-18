defmodule LiveTube.Model.Video do
  @moduledoc """
  Struct representing video file.
  """

  use LiveTubeWeb, :verified_routes
  alias __MODULE__

  defstruct [:upload, :extension, resolution: :original]

  @doc """
  Return new Video for upload path and original filename. Video extension is extracted from filename, and resolution will be :original.
  """
  def for_upload(path, filename) do
    upload_name = Path.basename(path)
    %Video{upload: upload_name, extension: extension(filename)}
  end

  @doc """
  Return copy of given video with resolution set to provided value.
  """
  def with_resolution(video, resolution) do
    %Video{upload: video.upload, extension: video.extension, resolution: resolution}
  end

  @doc """
  Return copy of given video with resolution set to :original.
  """
  def original(video) do
    %Video{upload: video.upload, extension: video.extension, resolution: :original}
  end

  @doc """
  Get filesystem path of underlying video file.
  """
  def path(video) do
    Path.join([:code.priv_dir(:live_tube), "static", "uploads", filename(video)])
  end

  @doc """
  Get server path of underlying video file, which can be ussed to access it in web application.
  """
  def src(video), do: ~p"/uploads/#{filename(video)}"

  defp filename(video), do: "#{video.upload}_#{video.resolution}.#{video.extension}"

  defp extension(filename), do: Enum.at(String.split(filename, "."), 1)
end
