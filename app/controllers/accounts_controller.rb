class AccountsController < ApplicationController
  layout "inertia", only: :edit

  before_action :ensure_can_administer, only: :update
  before_action :set_account
  before_action :load_sidebar_data, only: :edit

  def edit
    users = account_users.ordered.without_bots

    render inertia: "Accounts/Edit", props: {
      page: { title: "Account Settings", bodyClass: "sidebar" },
      account: AccountPresenter.new(@account).as_json,
      users: UserPresenter.collection(users, view: :account),
      currentUser: UserPresenter.new(Current.user, view: :minimal).as_json,
      canAdminister: Current.user.can_administer?,
      joinUrl: join_url(Current.account.join_code),
      logoUrl: helpers.fresh_account_logo_path,
      version: Rails.application.config.app_version,
      sidebar: {
        directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
        otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
        directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
        canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
      }
    }
  end

  def update
    @account.update!(account_params)

    if request.headers["X-Inertia"]
      redirect_to edit_account_url
    else
      redirect_to edit_account_url, notice: "✓"
    end
  end

  private
    def set_account
      @account = Current.account
    end

    def account_params
      params.require(:account).permit(:name, :logo, settings: {})
    end

    def account_users
      if Current.user.can_administer?
        User.where(status: [ :active, :banned ])
      else
        User.active
      end
    end

    def load_sidebar_data
      all_memberships = Current.user.memberships.visible.with_ordered_room
      @direct_memberships = all_memberships.select { |m| m.room.direct? }.sort_by { |m| m.room.updated_at }.reverse
      @other_memberships = all_memberships.without(@direct_memberships)

      exclude_user_ids = user_ids_already_in_direct_rooms.including(Current.user.id)
      @direct_placeholder_users = User.active.where.not(id: exclude_user_ids).order(:created_at).limit(20 - exclude_user_ids.count)
    end

    def user_ids_already_in_direct_rooms
      Membership.where(room_id: Current.user.rooms.directs.pluck(:id)).pluck(:user_id).uniq
    end
end
