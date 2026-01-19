class AccountPresenter < ApplicationPresenter
  def initialize(account)
    @account = account
  end

  def as_json
    {
      id: @account.id,
      name: @account.name,
      has_logo: @account.logo.attached?,
      settings: {
        restrict_room_creation_to_administrators: @account.settings.restrict_room_creation_to_administrators?
      }
    }
  end
end
