defmodule LiveTubeWeb.UploadLive do
  use LiveTubeWeb, :live_view
  alias LiveTube.Model.Video

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:video, nil)
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
    [video] = consume_uploaded_entries(socket, :video, &consume_upload/2)

    {:noreply,
     socket
     |> put_flash(:info, "Video uploaded")
     |> assign(:video, video)}
  end

  # @impl Phoenix.LiveView
  # def handle_info({:transcode_result, video}, socket) do
  #   socket = update(socket, :videos_in_progress, &MapSet.delete(&1, video.resolution))

  #   if MapSet.size(socket.assigns.videos_in_progress) == 0 do
  #     original = Video.original(video)
  #     File.rm(Video.path(original))
  #   end

  #   {:noreply, update(socket, :transcoded_videos, &[video | &1])}
  # end

  defp consume_upload(%{path: path}, entry) do
    video = Video.for_upload(path, entry.client_name)
    File.cp!(path, Video.path(video))
    {:ok, video}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
