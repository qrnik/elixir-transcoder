defmodule TranscoderWeb.UploadLive do
  use TranscoderWeb, :live_view
  alias Transcoder.Model.Video
  alias Transcoder.Server

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:transcoded_videos, [])
      |> allow_upload(:video, accept: ~w(video/*), max_file_size: 1_000_000_000)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    consume_uploaded_entries(socket, :video, &consume_upload/2)

    for video <- socket.assigns.transcoded_videos do
      File.rm(Video.path(video))
    end

    {:noreply,
     socket
     |> put_flash(:info, "Transcoding scheduled")
     |> assign(:transcoded_videos, [])
     |> assign(:videos_in_progress, MapSet.new(Server.supported_resolutions()))}
  end

  @impl Phoenix.LiveView
  def handle_info({:transcode_result, video}, socket) do
    socket = update(socket, :videos_in_progress, &MapSet.delete(&1, video.resolution))

    if MapSet.size(socket.assigns.videos_in_progress) == 0 do
      original = Video.original(video)
      File.rm(Video.path(original))
    end

    {:noreply, update(socket, :transcoded_videos, &[video | &1])}
  end

  defp consume_upload(%{path: path}, entry) do
    video = Video.for_upload(path, entry.client_name)
    File.cp!(path, Video.path(video))
    {:ok, pid} = Server.start_link()

    for resolution <- Server.supported_resolutions() do
      Server.transcode(pid, video, resolution)
    end

    {:ok, nil}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
