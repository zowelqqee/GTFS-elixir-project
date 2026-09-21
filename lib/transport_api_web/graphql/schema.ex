defmodule TransportApiWeb.Schema do
  use Absinthe.Schema

  import Ecto.Query

  alias TransportApi.Repo
  alias TransportApi.Stop

  input_object :route_input do
    field :gtfs_route_id, :string
    field :short_name, :string
    field :long_name, :string
    field :route_type, :integer
    field :transport_type, :string
    field :circular, :boolean
    field :urban, :boolean
    field :feed_version_id, :id
  end

  input_object :trip_input do
    field :gtfs_trip_id, :string
    field :direction_id, :integer
    field :route_id, :id
    field :service_id, :id
    field :shape_id, :id
    field :feed_version_id, :id
  end

  input_object :stop_input do
    field :gtfs_stop_id, :string
    field :name, :string
    field :lat, :float
    field :lon, :float
    field :location_type, :integer
    field :transport_type, :string
    field :feed_version_id, :id
  end

  object :route do
    field :id, :id
    field :gtfs_route_id, :string
    field :short_name, :string
    field :long_name, :string
    field :route_type, :integer
    field :transport_type, :string
    field :circular, :boolean
    field :urban, :boolean
    field :forward_length, :float
    field :backward_length, :float
    field :start_stop_name, :string
    field :end_stop_name, :string
    field :trip_count, :integer
  end


  object :stop do
    field :id, :id
    field :gtfs_stop_id, :string
    field :name, :string
    field :lat, :float
    field :lon, :float
    field :location_type, :integer
    field :transport_type, :string
  end

  object :trip do
    field :id, :id
    field :gtfs_trip_id, :string
    field :direction_id, :integer
    field :route_id, :id
    field :service_id, :id
  end

  object :stop_time do
    field :id, :id
    field :trip_id, :id
    field :stop_id, :id
    field :stop_sequence, :integer
    field :arrival_sec, :integer
    field :departure_sec, :integer
  end

  query do

    field :routes, list_of(:route) do
      arg :search, :string
      arg :transport_type, :string
      arg :sort_by, :string
      arg :sort_order, :string
      arg :page, :integer, default_value: 1
      arg :page_size, :integer, default_value: 20

      resolve(fn _, args, _ ->
        page = max(args.page, 1)
        page_size = min(max(args.page_size, 1), 100)

        query = from(r in TransportApi.Route)

        query =
          if args[:search] do
            search = "%#{args.search}%"
            from(r in query, where: ilike(r.short_name, ^search) or ilike(r.long_name, ^search))
          else
            query
          end

        query =
          if args[:transport_type] do
            from(r in query,
              where: r.transport_type == ^args.transport_type
            )
          else
            query
          end

        query =
          case args[:sort_by] do
            "name" -> from(r in query, order_by: [asc: r.long_name])
            "number" -> from(r in query, order_by: [asc: r.short_name])
            "transport_type" -> from(r in query, order_by: [asc: r.transport_type])
            _ -> from(r in query, order_by: [asc: r.id])
          end

        query = if args[:sort_order] == "desc" do
            case args[:sort_by] do
              "name" -> from(r in query, order_by: [desc: r.long_name])
              "number" -> from(r in query, order_by: [desc: r.short_name])

              "transport_type" -> from(r in query, order_by: [desc: r.transport_type])

              _ -> from(r in query, order_by: [desc: r.id])
            end
          else
            query
          end

        routes =
          query
          |> limit(^page_size)
          |> offset(^((page - 1) * page_size))
          |> Repo.all()

        result =
          Enum.map(routes, fn route ->
            trips = from(t in TransportApi.Trip, where: t.route_id == ^route.id)
            |> Repo.all()

            trip_count = length(trips)
            forward_trip = Enum.find(trips, fn trip -> trip.direction_id == 0 and not is_nil(trip.shape_id) end)
            backward_trip = Enum.find(trips, fn trip -> trip.direction_id == 1 and not is_nil(trip.shape_id) end)

            forward_length = if forward_trip do Repo.one( from sp in TransportApi.ShapePoint,
            where: sp.shape_id == ^forward_trip.shape_id,
            select: max(sp.dist_traveled))
            else
              nil
            end

            backward_length = if backward_trip do
                Repo.one( from sp in TransportApi.ShapePoint,
                    where: sp.shape_id == ^backward_trip.shape_id,
                    select: max(sp.dist_traveled))
              else
                nil
              end
            first_trip = List.first(trips)

            {start_name, end_name} =
              if first_trip do
                stop_times =
                  from(st in TransportApi.StopTime,
                    where: st.trip_id == ^first_trip.id,
                    order_by: st.stop_sequence,
                    preload: [:stop]
                  )
                  |> Repo.all()

                case stop_times do
                  [] -> {nil, nil}
                  list -> {List.first(list).stop.name, List.last(list).stop.name}
                end
              else
                {nil, nil}
              end

            %{
              id: route.id,
              gtfs_route_id: route.gtfs_route_id,
              short_name: route.short_name,
              long_name: route.long_name,
              route_type: route.route_type,
              transport_type: route.transport_type,
              circular: route.circular,
              urban: route.urban,
              start_stop_name: start_name,
              end_stop_name: end_name,
              trip_count: trip_count,
              forward_length: forward_length,
              backward_length: backward_length
            }
          end)

        {:ok, result}
      end)
    end
    field :stops, list_of(:stop) do
      resolve(fn _, _, _ -> {:ok, Repo.all(Stop)} end)
    end
    field :trips, list_of(:trip) do
      resolve(fn _, _, _ -> {:ok, Repo.all(TransportApi.Trip)} end)
    end
    field :schedule, list_of(:stop_time) do
      arg :stop_id, non_null(:id)

      resolve(fn _, %{stop_id: stop_id}, _ ->
        stop_times =
          TransportApi.StopTime
          |> where([st], st.stop_id == ^stop_id)
          |> Repo.all()

        {:ok, stop_times}
      end)
    end
  end

  mutation do
    field :create_route, :route do
    arg :input, non_null(:route_input)

    resolve(fn _, %{input: input}, _ ->
      %TransportApi.Route{}
      |> TransportApi.Route.changeset(input)
      |> Repo.insert()
    end)
  end

  field :update_route, :route do
    arg :id, non_null(:id)
    arg :input, non_null(:route_input)

    resolve(fn _, %{id: id, input: input}, _ ->
      case Repo.get(TransportApi.Route, id) do
        nil -> {:error, "route not found"}
        route -> route
          |> TransportApi.Route.changeset(input)
          |> Repo.update()
      end
    end)
  end

  field :delete_route, :route do
    arg :id, non_null(:id)

    resolve(fn _, %{id: id}, _ ->
      case Repo.get(TransportApi.Route, id) do
        nil -> {:error, "route not found"}
        route -> Repo.delete(route)
      end
    end)
  end


  field :create_trip, :trip do
    arg :input, non_null(:trip_input)

    resolve(fn _, %{input: input}, _ ->
      %TransportApi.Trip{}
      |> TransportApi.Trip.changeset(input)
      |> Repo.insert()
    end)
  end

  field :update_trip, :trip do
    arg :id, non_null(:id)
    arg :input, non_null(:trip_input)

    resolve(fn _, %{id: id, input: input}, _ ->
      case Repo.get(TransportApi.Trip, id) do
        nil ->
          {:error, "trip not found"}

        trip ->
          trip
          |> TransportApi.Trip.changeset(input)
          |> Repo.update()
      end
    end)
  end

  field :delete_trip, :trip do
    arg :id, non_null(:id)

    resolve(fn _, %{id: id}, _ ->
      case Repo.get(TransportApi.Trip, id) do
        nil -> {:error, "trip not found"}
        trip -> Repo.delete(trip)
      end
    end)
  end
    field :create_stop, :stop do
      arg :input, non_null(:stop_input)
      resolve(fn _, %{input: input}, _ -> %TransportApi.Stop{}
        |> TransportApi.Stop.changeset(input)
        |> Repo.insert()
      end)
    end

    field :update_stop, :stop do
      arg :id, non_null(:id)
      arg :input, non_null(:stop_input)

      resolve(fn _, %{id: id, input: input}, _ ->
        case Repo.get(TransportApi.Stop, id) do
          nil -> {:error, "stop not found"}
          stop -> stop
            |> TransportApi.Stop.changeset(input)
            |> Repo.update()
        end
      end)
    end

    field :delete_stop, :stop do
      arg :id, non_null(:id)
      resolve(fn _, %{id: id}, _ ->
        case Repo.get(TransportApi.Stop, id) do
          nil -> {:error, "stop not found"}
          stop -> Repo.delete(stop)
        end
      end)
    end
  end
end
