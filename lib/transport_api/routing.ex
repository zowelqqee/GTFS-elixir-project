defmodule TransportApi.Routing do
  import Ecto.Query
  alias TransportApi.Repo
  alias TransportApi.StopTime
  alias TransportApi.Stop

  def nearby_stops(stop_id) do
    stop = Repo.get!(Stop, stop_id)

    lat_delta = 0.005
    lon_delta = 0.010

    from(s in Stop,
    where:  s.feed_version_id == ^stop.feed_version_id and
    s.lat >= ^(stop.lat - lat_delta) and s.lat <= ^(stop.lat + lat_delta) and s.lon >= ^(stop.lon - lon_delta) and s.lon <= ^(stop.lon + lon_delta))
    |> Repo.all()
    |> Enum.filter(fn other -> distance_m(stop, other) <= 500 end)
  end
  def distance_m(stop1, stop2) do
    r = 6_371_000

    lat1 = stop1.lat * :math.pi() / 180
    lat2 = stop2.lat * :math.pi() / 180

    dlat = lat2 - lat1
    dlon = (stop2.lon - stop1.lon) * :math.pi() / 180

    a = :math.sin(dlat / 2) ** 2 + :math.cos(lat1) * :math.cos(lat2) * :math.sin(dlon / 2) ** 2
    2 * r * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
  end

  def direct_routes(from_stop_id, to_stop_id, departure_sec) do
    from_st = from(st in StopTime,
    where: st.stop_id == ^from_stop_id and st.departure_sec >= ^departure_sec)

    to_st = from(st in StopTime,
    where: st.stop_id == ^to_stop_id)

    from(f in subquery(from_st),
    join: t in subquery(to_st),
    on: f.trip_id == t.trip_id and f.stop_sequence < t.stop_sequence,
    order_by: [asc: t.arrival_sec],
    limit: 3,
    select: %{
      trip_id: f.trip_id,
      depareture_sec: f.departure_sec,
      arrival_sec: t.arrival_sec,
      from_sequence: f.stop_sequence,
      to_sequence: t.stop_sequence
    })
    |> Repo.all()
  end

  def one_transfer_routes(from_stop_id, to_stop_id, departure_sec) do
    first = from(a in StopTime,
    join: x in StopTime,
    on: a.trip_id == x.trip_id and a.stop_sequence < x.stop_sequence,
    where: a.stop_id == ^from_stop_id and a.departure_sec >= ^departure_sec,
    order_by: [asc: a.departure_sec],
    limit: 30,
    select: %{
          first_trip_id: a.trip_id,
          transfer_stop_id: x.stop_id,
          departure_sec: a.departure_sec,
          transfer_arrival_sec: x.arrival_sec})
    |> Repo.all()

    first
    |> Enum.flat_map(fn first -> nearby_ids = nearby_stops(first.transfer_stop_id)|> Enum.map(fn x -> x.id end)
      second = from(y in StopTime,
      join: b in StopTime,
      on: y.trip_id == b.trip_id and y.stop_sequence < b.stop_sequence,
      where: y.stop_id in ^nearby_ids and b.stop_id == ^to_stop_id and y.departure_sec >= ^(first.transfer_arrival_sec + 120) and y.trip_id != ^first.first_trip_id,
      select: %{
        second_trip_id: y.trip_id,
        transfer_to_stop_id: y.stop_id,
        transfer_departure_sec: y.departure_sec,
        arrival_sec: b.arrival_sec
      })
        |> Repo.all()

      Enum.map(second, fn second ->
        %{
          first_trip_id: first.first_trip_id,
          second_trip_id: second.second_trip_id,

          transfer_from_stop_id: first.transfer_stop_id,
          transfer_to_stop_id: second.transfer_to_stop_id,

          departure_sec: first.departure_sec,
          transfer_arrival_sec: first.transfer_arrival_sec,
          transfer_departure_sec: second.transfer_departure_sec,
          arrival_sec: second.arrival_sec
        }
      end)
    end)
    |> Enum.sort_by(fn x -> x.arrival_sec end)
    |> Enum.take(3)
  end
end
