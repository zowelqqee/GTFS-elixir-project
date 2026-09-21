defmodule TransportApi.Routing do
  import Ecto.Query

  alias TransportApi.Repo
  alias TransportApi.StopTime

  def direct_routes(from_stop_id, to_stop_id, departure_sec) do
    from_st = from(st in StopTime, where: st.stop_id == ^from_stop_id and st.departure_sec >= ^departure_sec)
    to_st = from(st in StopTime, where: st.stop_id == ^to_stop_id)

    from(f in subquery(from_st),
      join: t in subquery(to_st), on: f.trip_id == t.trip_id and f.stop_sequence < t.stop_sequence, order_by: [asc: t.arrival_sec], limit: 3, select: %{
        trip_id: f.trip_id,
        departure_sec: f.departure_sec,
        arrival_sec: t.arrival_sec,
        from_sequence: f.stop_sequence,
        to_sequence: t.stop_sequence
      }
    )
    |> Repo.all()
  end
end
