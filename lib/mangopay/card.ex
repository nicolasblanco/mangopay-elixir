defmodule Mangopay.Card do
  alias Mangopay.User, as: User
  alias Mangopay.Transaction, as: Transaction

  use Mangopay.Query.Base, "cards"
  set_action "cards", [{:get}]
  def get_registration id do
    _get ["cardregistrations", id]
  end

  def create params do
    _create params, ["cardregistrations"]
  end

  def update id, params do
    _update params, ["cardregistrations", id]
  end

  def all_by_fingerprints id do
    _all [resource(), "fingerprints", id]
  end

  def all_by_user id do
    _all [User.path(), id, resource()]
  end

  def all_user_by_fingerprint fingerprint do
    _all [resource(), "fingerprints", fingerprint, User.path()]
  end

  def deactivate id, params do
    _update params, id
  end

  def all_transactions_by_fingerprint fingerprint do
    _all [resource(), "fingerprints", "#{fingerprint}", Transaction.path()]
  end
end
