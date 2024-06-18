defmodule Transcoder.Server do
  @moduledoc """
  GenServer that offers transcoding operations for videos.
  """

  use GenServer
  use TranscoderWeb, :verified_routes
  alias Transcoder.Model.Video

  @supported_resolutions ~w(360p 480p 720p)a

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Asynchronously create copy of video in provided resolution. On completion, caller receives message of form: {:transcode_result, Transcoder.Model.Video}
  """
  def transcode(pid, video, resolution) when resolution in @supported_resolutions do
    GenServer.cast(pid, {:transcode, video, resolution, self()})
  end

  def transcode(_pid, _video, resolution) do
    raise "Unsupported resolution: #{resolution}"
  end

  def supported_resolutions, do: @supported_resolutions

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:transcode, video, resolution, from}, _state) do
    scaled_video = do_transcode(video, resolution)
    send(from, {:transcode_result, scaled_video})
    {:noreply, nil}
  end

  defp do_transcode(video, resolution) do
    new_video = Video.with_resolution(video, resolution)

    {_, 0} =
      System.cmd(
        "ffmpeg",
        ~w(-i #{Video.path(video)} -vf scale=#{scale(resolution)} #{Video.path(new_video)})
      )

    new_video
  end

  defp scale(resolution) do
    case resolution do
      :"360p" -> "640:360"
      :"480p" -> "854:480"
      :"720p" -> "1280:720"
    end
  end
end
