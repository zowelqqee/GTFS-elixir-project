defmodule TransportApi.GTFS.FeedWorker do
  use GenServer

  alias TransportApi.Repo
  alias TransportApi.FeedVersion
  alias TransportApi.GTFS.Importer

  @feed_url "https://transport.orgp.spb.ru/Portal/transport/internalapi/gtfs/feed.zip"
  @check_interval :timer.hours(24)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    IO.puts("worker started")
    send(self(), :check_feed)
    {:ok, state}
  end

  @impl true
  def handle_info(:check_feed, state) do
    check_feed()
    Process.send_after(self(), :check_feed, @check_interval)
    {:noreply, state}
  end

  defp check_feed do
    IO.puts("checking feed...")
    case Req.get(@feed_url, connect_options: [transport_opts: [verify: :verify_none]]) do
      {:ok, %{status: 200, body: body}} -> process_feed(body)
      {:ok, response} -> IO.inspect("download failed: HTTP #{response.status}")
      {:error, reason} -> IO.inspect(reason, label: "download error")
    end
  end

  defp process_feed(body) do
    hash = :crypto.hash(:sha256, body)
    |> Base.encode16(case: :lower)

    case Repo.get_by(FeedVersion, content_hash: hash) do
      nil -> create_new_version(body, hash)
      _existing -> IO.inspect("feed has not changed")
    end
  end

  defp create_new_version(body, hash) do
    date = Date.utc_today()
    |> Date.to_iso8601()
    archive_path = "feeds/#{date}-#{String.slice(hash, 00, 8)}.zip"

    File.mkdir_p("feeds")
    File.write!(archive_path, body)

    {:ok, feed_version} =
      %FeedVersion{}
      |> FeedVersion.changeset(%{source: @feed_url, content_hash: hash, status: "importing", started_at: DateTime.utc_now(), archive_path: archive_path})
      |> Repo.insert()
    IO.inspect("Created feed version #{feed_version.id}")

    import_feed(feed_version, archive_path)
  end

  defp import_feed(feed_version, archive_path) do
    extract_dir = "tmp/gtfs/#{feed_version.id}"
    File.rm_rf!(extract_dir)
    File.mkdir_p!(extract_dir)

    {:ok, _files} = :zip.extract(String.to_charlist(archive_path), cwd: String.to_charlist(extract_dir))
    Importer.import_stops("#{extract_dir}/stops.txt", feed_version.id)
    Importer.import_routes("#{extract_dir}/routes.txt", feed_version.id)
    Importer.import_services("#{extract_dir}/calendar.txt", feed_version.id)
    Importer.import_service_exceptions("#{extract_dir}/calendar_dates.txt",feed_version.id)
    Importer.import_shapes("#{extract_dir}/shapes.txt", feed_version.id)
    Importer.import_trips("#{extract_dir}/trips.txt", feed_version.id)
    Importer.import_stop_times("#{extract_dir}/stop_times.txt", feed_version.id)
    Importer.import_frequencies("#{extract_dir}/frequencies.txt", feed_version.id)

    feed_version
    |> FeedVersion.changeset(%{status: "active", finished_at: DateTime.utc_now(), activated_at: DateTime.utc_now()})
    |> Repo.update()
    IO.inspect("feed version #{feed_version.id} imported")

    File.rm_rf(extract_dir)

  end
end
