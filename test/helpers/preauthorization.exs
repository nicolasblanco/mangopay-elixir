ExUnit.start()

defmodule PreauthorizationHelper do
  defmacro __using__(opts\\nil) do
    quote do
      def fixture_path path do
        "fixture/vcr_cassettes" <> path
      end

      def get_json path do
        a = fixture_path(path) |> File.read! |> Poison.decode! |> List.last
        b = a["response"]["body"]
        case Poison.decode b do
          {:ok, val}        -> val
          {:error, message} -> b
        end
      end

      def created_preauthorization(module_name \\ nil) do
        get_json Enum.join(Enum.filter(["", module_name(__MODULE__), "preauthorization", "create.json"], & !is_nil(&1)), "/")
      end

      def created_preauthorization_bis(module_name \\ nil) do
        get_json Enum.join(Enum.filter(["", module_name(__MODULE__), "preauthorization", "create_bis.json"], & !is_nil(&1)), "/")
      end
      def preauthorization_hash do
        %{
          "Tag": "custom meta",
          "AuthorId": created_user()["Id"],
          "DebitedFunds": %{
            "Currency": "EUR",
            "Amount": 5550
          },
          "Billing": %{
            "Address": %{
              "AddressLine1": "1 Mangopay Street",
              "AddressLine2": "The Loop",
              "City": "Paris",
              "Region": "Ile de France",
              "PostalCode": "755001",
              "Country": "FR"
            }
          },
          "SecureMode": "DEFAULT",
          "CardId": created_card()["Id"],
          "SecureModeReturnURL": "http://www.my-site.com/returnURL"
        }
      end

      def cancel_preauthorization_hash do
        %{
          "Tag": "custom meta",
          "PaymentStatus": "CANCELED"
        }
      end

      def create_preauthorization_cassette do
        use_cassette "#{module_name(__MODULE__)}/preauthorization/create" do
          Mangopay.PreAuthorization.create preauthorization_hash()
        end
      end

      def cancel_preauthorization_cassette do
        use_cassette "#{module_name(__MODULE__)}/preauthorization/cancel" do
          Mangopay.PreAuthorization.cancel created_preauthorization()["Id"], cancel_preauthorization_hash()
        end
      end
    end
  end
end
