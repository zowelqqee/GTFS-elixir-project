defmodule TransportApiWeb.FeedController do
  use TransportApiWeb, :controller

  import Ecto.Query

  alias TransportApi.Repo
  alias TransportApi.FeedVersion

  def download(conn, %{"date" => date}) do
    with {:ok, parsed_date} <- Date.from_iso8601(date),
      %FeedVersion{} = feed <- find_feed(parsed_date),
      true <- File.exists?(feed.archive_path) do
        send_download(conn, {:file, feed.archive_path}, filename: "feed-#{date}.zip")
    else
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid date"})
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "feed not found"})
      false ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "archive file not found"}) end
  end

  defp find_feed(date) do
    start_of_day = NaiveDateTime.new!(date, ~T[00:00:00])
    end_of_day = NaiveDateTime.new!(date, ~T[23:59:59])

    from(f in FeedVersion,
      where:
        f.inserted_at >= ^start_of_day and f.inserted_at <= ^end_of_day, order_by: [desc: f.inserted_at], limit: 1
    )
    |> Repo.one()
  end
end
