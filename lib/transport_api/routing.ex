defmodule TransportApi.Routing do
  import Ecto.Query
  alias TransportApi.Repo
  alias TransportApi.StopTime
  alias TransportApi.Stop
  def distance_m(stop1, stop2) do
    r = 6_371_000

    lat1 = stop1.lat * :math.pi() / 180
    lat2 = stop2.lat * :math.pi() / 180

    dlat = lat2 - lat1
    dlon = (stop2.lon - stop1.lon) * :math.pi() / 180

    a =
      :math.sin(dlat / 2) ** 2 +
        :math.cos(lat1) *
          :math.cos(lat2) *
          :math.sin(dlon / 2) ** 2

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
    first =
      from(a in StopTime,
        join: x in StopTime,
        on:
          a.trip_id == x.trip_id and
            a.stop_sequence < x.stop_sequence,
        where:
          a.stop_id == ^from_stop_id and
            a.departure_sec >= ^departure_sec,
        select: %{
          first_trip_id: a.trip_id,
          transfer_from_stop_id: x.stop_id,
          first_departure_sec: a.departure_sec,
          transfer_arrival_sec: x.arrival_sec
        }
      )

    second =
      from(y in StopTime,
        join: b in StopTime,
        on:
          y.trip_id == b.trip_id and
            y.stop_sequence < b.stop_sequence,
        where: b.stop_id == ^to_stop_id,
        select: %{
          second_trip_id: y.trip_id,
          transfer_to_stop_id: y.stop_id,
          transfer_departure_sec: y.departure_sec,
          final_arrival_sec: b.arrival_sec
        }
      )

    from(f in subquery(first),
      join: from_stop in Stop,
      on: from_stop.id == f.transfer_from_stop_id,

      join: s in subquery(second),
      on: f.first_trip_id != s.second_trip_id,

      join: to_stop in Stop,
      on: to_stop.id == s.transfer_to_stop_id,

      where:
        s.transfer_departure_sec >=
          f.transfer_arrival_sec + 120,

      order_by: [asc: s.final_arrival_sec],

      select: %{
        first_trip_id: f.first_trip_id,
        second_trip_id: s.second_trip_id,

        transfer_from_stop_id: f.transfer_from_stop_id,
        transfer_to_stop_id: s.transfer_to_stop_id,

        from_lat: from_stop.lat,
        from_lon: from_stop.lon,
        to_lat: to_stop.lat,
        to_lon: to_stop.lon,

        departure_sec: f.first_departure_sec,
        transfer_arrival_sec: f.transfer_arrival_sec,
        transfer_departure_sec: s.transfer_departure_sec,
        arrival_sec: s.final_arrival_sec}
    )
    |> Repo.all()
    |> Enum.filter(fn route ->
      stop1 = %{lat: route.from_lat, lon: route.from_lon}
      stop2 = %{lat: route.to_lat, lon: route.to_lon}
      distance_m(stop1, stop2) <= 500 end)
    |> Enum.take(3)

  end
end
