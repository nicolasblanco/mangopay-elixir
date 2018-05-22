defmodule MangoPay do
  @moduledoc """
  The elixir client for MangoPay API.

  This module is the root of all the application.

  ## Configuring
  Set your API key by configuring the :mangopay application.

  ```
    config :mangopay, :client, id: YOUR_MANGOPAY_CLIENT_ID
    config :mangopay, :client, passphrase: MANGOPAY_PLATFORM_KEY
  ```
  """

  @base_header %{"User-Agent": "Elixir", "Content-Type": "application/json"}

  @payline_header %{"Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Accept": "*/*", "Host": "homologation-webpayment.payline.com"}

  def base_header do
    @base_header
  end

  @doc """
  Returns MANGOPAY_BASE_URL
  """
  def base_url do
    "https://api.sandbox.mangopay.com"
  end


  @doc """
  Returns MANGOPAY_CLIENT
  """
  def client do
    Application.get_env(:mangopay, :client)
  end

  def mangopay_version do
    "v2.01"
  end

  def mangopay_version_and_client_id do
    "/#{mangopay_version()}/#{MangoPay.client()[:id]}"
  end

  @doc """
  Request to mangopay web API.

  ## Examples

      response = MangoPay.request!("get", "users")

  """
  def request! {method, url, body, headers} do
    request!(method, url, body, headers)
  end

  def request! {_method, url, query} do
    request!(:get, url, "", "", query)
  end

  def request!(method, url, body \\ "", headers \\ "", query \\ %{}) do
    {method, url, body, headers, _} = full_header_request(method, url, body, headers, query)

    filter_and_send(method, url, body, headers, query, true)
    |> decode_body()
    |> underscore_map()
  end

  @doc """
  Request to mangopay web API.

  ## Examples

      {:ok, response} = MangoPay.request({"get", "users", nil, nil})

  """
  def request {method, url, body, headers} do
    request(method, url, body, headers)
  end

  def request {_method, url, query} do
    request(:get, url, "", "", query)
  end

  @doc """
  Request to mangopay web API.

  ## Examples

      {:ok, response} = MangoPay.request("get", "users")

  """
  def request(method, url, body \\ "", headers \\ "", query \\ %{}) do
    {method, url, body, headers, query} = full_header_request(method, url, body, headers, query)

    case filter_and_send(method, url, body, headers, query, false) do
      {:ok, response} -> {:ok, decode_body(response) |> underscore_map()}
      {:error, error} -> {:error, error}
    end
  end

  defp decode_body(%{body: body}) do
    case Poison.decode(body) do
      {:ok, decoded_body} -> decoded_body
      {:error, _} -> body
    end
  end

  defp underscore_map(%{} = map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) ->
      underscored_key = underscore_word(k) |> String.to_atom

      cond do
        is_map(v) -> Map.put_new(acc, underscored_key, underscore_map(v))
        true -> Map.put_new(acc, underscored_key, v)
      end
    end)
  end
  defp underscore_map(result) when is_list(result), do: Enum.map(result, &(underscore_map(&1)))
  defp underscore_map(result), do: result

  defp underscore_word(word) do
    word
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/-/, "_")
    |> String.downcase
  end

  def camelize_map(%{} = map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) ->
      camelized_key = camelize_word(k)

      cond do
        is_map(v) -> Map.put_new(acc, camelized_key, camelize_map(v))
        true -> Map.put_new(acc, camelized_key, v)
      end
    end)
  end

  def camelize_word(word) do
    case Regex.split(~r/(?:^|[-_])|(?=[A-Z])/, to_string(word)) do
      words ->
        words |> Enum.filter(&(&1 != "")) |> camelize_list()
        |> Enum.join()
    end
  end

  defp camelize_list([]), do: []
  defp camelize_list([h|tail]) do
    [String.capitalize(h)] ++ camelize_list(tail)
  end

  defp full_header_request(method, url, body, headers, query) do
    {method, url, decode_map(body), headers, query}
      |> authorization_params()
      |> payline_params()
  end

  defp authorization_params {method, url, body, headers, query} do
    headers = case headers do
      %{"Authorization": _}   -> headers
      _  -> Map.merge(base_header(), %{"Authorization": "#{MangoPay.Authorization.pull_token()}"})
    end
    {method, url, body, headers, query}
  end

  defp payline_params {method, url, body, headers, query} do
    if String.contains?(url, "payline") do
      {method, url, body, cond_payline(headers), query}
    else
      {method, cond_mangopay(url), body, headers, query}
    end
  end

  defp cond_payline headers do
    headers
    |> Map.update!(:"Content-Type", fn _ -> "application/x-www-form-urlencoded" end)
    |> Map.merge(@payline_header)
  end

  defp cond_mangopay url do
    base_url() <> mangopay_version_and_client_id() <> url
  end

  defp decode_map(body) when is_map(body) do
    body
    |> camelize_map()
    |> Poison.encode!
  end
  defp decode_map(body) when is_list(body), do: Poison.encode!(body)
  defp decode_map(body) when is_binary(body), do: body

  # default request send to mangopay
  defp filter_and_send(method, url, body, headers, query, true) do
    case Mix.env do
      :test -> HTTPoison.request!(method, url, body, headers, [params: query, timeout: 500000, recv_timeout: 500000])
      _ ->     HTTPoison.request!(method, url, body, headers, [params: query, timeout: 4600, recv_timeout: 5000])
    end
  end
  defp filter_and_send(method, url, body, headers, query, _bang) do
    case Mix.env do
      :test -> HTTPoison.request(method, url, body, headers, [params: query, timeout: 500000, recv_timeout: 500000])
      _ ->     HTTPoison.request(method, url, body, headers, [params: query, timeout: 4600, recv_timeout: 5000])
    end
  end
end
