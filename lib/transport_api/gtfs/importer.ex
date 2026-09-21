NimbleCSV.define(TransportApi.GTFS.CSVParser,
  separator: ",",
  escape: "\""
)

defmodule TransportApi.GTFS.Importer do
  alias TransportApi.Repo
  alias TransportApi.Stop
  alias TransportApi.Route
  alias TransportApi.Service
  alias TransportApi.ServiceException
  alias TransportApi.Shape
  alias TransportApi.ShapePoint
  alias TransportApi.Trip
  alias TransportApi.StopTime
  alias TransportApi.Frequency
  alias TransportApi.GTFS.CSVParser

  import Ecto.Query

  #stops

  def import_stops(path, feed_version_id) do
    import_file(path, Stop, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        gtfs_stop_id: row["stop_id"],
        name: row["stop_name"],
        lat: to_float(row["stop_lat"]),
        lon: to_float(row["stop_lon"]),
        location_type: to_int(row["location_type"]),
        transport_type: row["transport_type"],
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #routes

  def import_routes(path, feed_version_id) do
    import_file(path, Route, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        gtfs_route_id: row["route_id"],
        short_name: row["route_short_name"],
        long_name: row["route_long_name"],
        route_type: to_int(row["route_type"]),
        transport_type: row["transport_type"],
        circular: to_bool(row["circular"]),
        urban: to_bool(row["urban"]),
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #services

  def import_services(path, feed_version_id) do
    import_file(path, Service, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        gtfs_service_id: row["service_id"],
        monday: to_bool(row["monday"]),
        tuesday: to_bool(row["tuesday"]),
        wednesday: to_bool(row["wednesday"]),
        thursday: to_bool(row["thursday"]),
        friday: to_bool(row["friday"]),
        saturday: to_bool(row["saturday"]),
        sunday: to_bool(row["sunday"]),
        start_date: to_date(row["start_date"]),
        end_date: to_date(row["end_date"]),
        name: row["service_name"],
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #dates

  def import_service_exceptions(path, feed_version_id) do
    services = service_lookup(feed_version_id)

    import_file(path, ServiceException, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        service_id: Map.fetch!(services, row["service_id"]),
        date: to_date(row["date"]),
        exception_type: to_int(row["exception_type"]),
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #shapes

  def import_shapes(path, feed_version_id) do
    # Сначала создаём сами Shape по уникальным shape_id
    shape_ids =
      path
      |> rows()
      |> Stream.map(& &1["shape_id"])
      |> Enum.uniq()

    now = now()

    shapes =
      Enum.map(shape_ids, fn shape_id ->
        %{
          feed_version_id: feed_version_id,
          gtfs_shape_id: shape_id,
          inserted_at: now,
          updated_at: now
        }
      end)

    shapes
    |> Enum.chunk_every(1000)
    |> Enum.each(fn batch ->
      Repo.insert_all(Shape, batch)
    end)

    shape_lookup = shape_lookup(feed_version_id)

    # Потом точки
    path
    |> rows()
    |> Stream.map(fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        shape_id: Map.fetch!(shape_lookup, row["shape_id"]),
        seq: to_int(row["shape_pt_sequence"]),
        lat: to_float(row["shape_pt_lat"]),
        lon: to_float(row["shape_pt_lon"]),
        dist_traveled: to_float(row["shape_dist_traveled"]),
        inserted_at: now,
        updated_at: now
      }
    end)
    |> Stream.chunk_every(1000)
    |> Enum.each(fn batch ->
      Repo.insert_all(ShapePoint, batch)
    end)
  end

  #trips

  def import_trips(path, feed_version_id) do
    routes = route_lookup(feed_version_id)
    services = service_lookup(feed_version_id)
    shapes = shape_lookup(feed_version_id)

    import_file(path, Trip, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,
        gtfs_trip_id: row["trip_id"],

        route_id:
          Map.fetch!(
            routes,
            row["route_id"]
          ),

        service_id:
          Map.fetch!(
            services,
            row["service_id"]
          ),

        direction_id: to_int(row["direction_id"]),

        # У части trips shape отсутствует или битый.
        shape_id: Map.get(shapes, row["shape_id"]),

        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #stop times

  def import_stop_times(path, feed_version_id) do
    trips = trip_lookup(feed_version_id)
    stops = stop_lookup(feed_version_id)
    shapes = shape_lookup(feed_version_id)

    import_file(path, StopTime, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,

        trip_id: Map.fetch!(trips,row["trip_id"]),

        stop_id: Map.fetch!( stops, row["stop_id"]),

        stop_sequence: to_int(row["stop_sequence"]),
        arrival_sec: to_seconds(row["arrival_time"]),
        departure_sec: to_seconds(row["departure_time"]),
        shape_dist_traveled: to_float(row["shape_dist_traveled"]),

        segment_shape_id: Map.get( shapes,row["shape_id"]),

        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #freqs

  def import_frequencies(path, feed_version_id) do
    trips = trip_lookup(feed_version_id)

    import_file(path, Frequency, fn row ->
      now = now()

      %{
        feed_version_id: feed_version_id,

        trip_id: Map.fetch!( trips, row["trip_id"]),

        start_sec: to_seconds(row["start_time"]),
        end_sec: to_seconds(row["end_time"]),
        headway_secs: to_int(row["headway_secs"]),
        exact_times: to_int(row["exact_times"]),
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  #csv import

  defp import_file(path, schema, mapper) do
    path
    |> rows()
    |> Stream.map(mapper)
    |> Stream.chunk_every(1000)
    |> Enum.each(fn batch ->
      Repo.insert_all(schema, batch)
    end)
  end
  defp rows(path) do
    path
    |> File.stream!()
    |> CSVParser.parse_stream(skip_headers: false)
    |> Stream.transform(nil, fn
      header, nil ->
        {[], header}

      row, header ->
        map =
          header
          |> Enum.zip(row)
          |> Map.new()

        {[map], header}
    end)
  end

  #lookpus

  defp stop_lookup(feed_version_id) do
    from(s in Stop,
      where: s.feed_version_id == ^feed_version_id,
      select: {s.gtfs_stop_id, s.id}
    )
    |> Repo.all()
    |> Map.new()
  end

  defp route_lookup(feed_version_id) do
    from(r in Route,
      where: r.feed_version_id == ^feed_version_id,
      select: {r.gtfs_route_id, r.id}
    )
    |> Repo.all()
    |> Map.new()
  end

  defp service_lookup(feed_version_id) do
    from(s in Service, where: s.feed_version_id == ^feed_version_id, select: {s.gtfs_service_id, s.id} )
    |> Repo.all()
    |> Map.new()
  end

  defp shape_lookup(feed_version_id) do
    from(s in Shape, where: s.feed_version_id == ^feed_version_id, select: {s.gtfs_shape_id, s.id})
    |> Repo.all()
    |> Map.new()
  end

  defp trip_lookup(feed_version_id) do
    from(t in Trip, where: t.feed_version_id == ^feed_version_id, select: {t.gtfs_trip_id, t.id})
    |> Repo.all()
    |> Map.new()
  end

  #types

  defp to_float(nil), do: nil
  defp to_float(""), do: nil
  defp to_float(value), do: String.to_float(value)

  defp to_int(nil), do: nil
  defp to_int(""), do: nil
  defp to_int(value), do: String.to_integer(value)

  defp to_bool("1"), do: true
  defp to_bool("0"), do: false
  defp to_bool(nil), do: nil
  defp to_bool(""), do: nil

  defp to_date(nil), do: nil
  defp to_date(""), do: nil

  defp to_date(
         <<year::binary-size(4),
           month::binary-size(2),
           day::binary-size(2)>>
       ) do
    Date.new!(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day)
    )
  end

  defp to_seconds(nil), do: nil
  defp to_seconds(""), do: nil

  defp to_seconds(value) do
    [hours, minutes, seconds] =
      value
      |> String.split(":")
      |> Enum.map(&String.to_integer/1)

    hours * 3600 + minutes * 60 + seconds
  end

  defp now do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end
end
