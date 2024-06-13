defmodule TranscoderWeb.UploadLive do
  alias Transcoder.Model.Video
  use TranscoderWeb, :live_view

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

    {:noreply,
     socket
     |> put_flash(:info, "Transcoding scheduled")
     |> assign(:transcoded_videos, [])}
  end

  @impl Phoenix.LiveView
  def handle_info({:transcode_result, video}, socket) do
    {:noreply, update(socket, :transcoded_videos, &[video | &1])}
  end

  defp consume_upload(%{path: path}, entry) do
    [_, extension] = String.split(entry.client_name, ".")
    filename = Path.basename(path) <> "." <> extension
    video = %Video{filename: filename}
    File.cp!(path, Video.path(video))
    {:ok, pid} = Transcoder.start_link()

    for resolution <- [:"360p", :"480p", :"720p"] do
      Transcoder.transcode(pid, video, resolution)
    end

    {:ok, nil}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
