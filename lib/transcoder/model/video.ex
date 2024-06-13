defmodule Transcoder.Model.Video do
  use TranscoderWeb, :verified_routes

  defstruct [:filename, resolution: :original]

  def path(video) do
    Path.join([:code.priv_dir(:transcoder), "static", "uploads", video.filename])
  end

  def src(video), do: ~p"/uploads/#{video.filename}"
end
