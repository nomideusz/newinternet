class Users::ProfilesController < ApplicationController
  layout "inertia"

  before_action :set_user

  def show
    memberships = Current.user.memberships.with_ordered_room

    render inertia: "Users/Profiles/Show", props: {
      page: { title: @user.name, bodyClass: "sidebar" },
      profile: UserPresenter.new(@user, view: :profile).as_json,
      memberships: memberships.map { |m| MembershipPresenter.new(m, view: :profile).as_json },
      transferUrl: session_transfer_url(@user.transfer_id)
    }
  end

  def update
    @user.update user_params

    if request.headers["X-Inertia"]
      redirect_to user_profile_url
    else
      redirect_to user_profile_url, notice: update_notice
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def user_params
      params.require(:user).permit(:avatar, :bio).compact
    end

    def update_notice
      params[:user][:avatar] ? "It may take up to 30 minutes to change everywhere." : "✓"
    end
end
