defmodule Transcoder do
  use GenServer
  use TranscoderWeb, :verified_routes
  alias Transcoder.Model.Video

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def transcode(pid, video, resolution) do
    GenServer.cast(pid, {:transcode, video, resolution, self()})
  end

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

  defp do_transcode(original, resolution) do
    new_filename = transcoded_filename(original.filename, resolution)
    new_video = %Video{filename: new_filename, resolution: resolution}
    {_, 0} = System.cmd("ffmpeg", ~w(-i #{Video.path(original)} -vf scale=#{scale(resolution)} #{Video.path(new_video)}))
    new_video
  end

  defp scale(resolution) do
    case resolution do
      :"360p" -> "640:360"
      :"480p" -> "854:480"
      :"720p" -> "1280:720"
    end
  end

  defp transcoded_filename(filename, resolution) do
    [name, extension] = String.split(filename, ".")
    "#{name}_#{resolution}.#{extension}"
  end
end
