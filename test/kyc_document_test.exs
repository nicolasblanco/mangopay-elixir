defmodule KycDocumentTest do
  use Helper
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    use_cassette "user/natural/create" do
      Mangopay.User.Natural.create user_natural_hash
    end
    use_cassette "kyc_document/user/create" do
      Mangopay.KycDocument.create_to_user created_user["Id"], kyc_document_hash
    end
    use_cassette "kyc_document/user/create_page" do
      Mangopay.KycDocument.create_page_to_user_kyc_document created_user["Id"], created_kyc_document["Id"], kyc_document_page_hash
    end
    use_cassette "kyc_document/submit" do
      Mangopay.KycDocument.submit created_user["Id"], created_kyc_document["Id"], submit_kyc_document_hash
    end
    :ok
  end

  test "create kyc_document to user" do
    use_cassette "kyc_document/user/create" do
      assert {:ok, response} = Mangopay.KycDocument.create_to_user created_user["Id"], kyc_document_hash
      assert Poison.decode!(response.body)["Status"] == "CREATED"
    end
  end

  test "submit kyc_document to user kyc document" do
    use_cassette "kyc_document/submit" do
      assert {:ok, response} = Mangopay.KycDocument.submit created_user["Id"], created_kyc_document["Id"], submit_kyc_document_hash
      assert Poison.decode!(response.body)["Status"] == "VALIDATION_ASKED"
    end
  end

  test "create page to user kyc_document" do
    use_cassette "kyc_document/user/create_page" do
      assert {:ok, response} = Mangopay.KycDocument.create_page_to_user_kyc_document created_user["Id"], created_kyc_document["Id"], kyc_document_page_hash
      assert response.body == ""
    end
  end

  test "get user" do
    use_cassette "kyc_document/get" do
      assert {:ok, response} = Mangopay.KycDocument.get created_kyc_document["Id"]
      assert Poison.decode!(response.body)["Id"] == created_kyc_document["Id"]
    end
  end

  test "all kyc_document by user" do
    use_cassette "kyc_document/user/all" do
      assert {:ok, response} = Mangopay.KycDocument.all_by_user created_user["Id"]
      assert length(Poison.decode!(response.body)) > 0
    end
  end

  test "all kyc_document" do
    use_cassette "kyc_document/all" do
      assert {:ok, response} = Mangopay.KycDocument.all
      assert length(Poison.decode!(response.body)) > 0
    end
  end
end
