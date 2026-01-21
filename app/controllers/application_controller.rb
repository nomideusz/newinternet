class ApplicationController < ActionController::Base
  include AllowBrowser, Authentication, Authorization, BlockBannedRequests, SetCurrentRequest, SetPlatform, TrackedRoomVisit, VersionHeaders
  include Turbo::Streams::Broadcasts, Turbo::Streams::StreamName

  # Shared data available to all Inertia pages
  # Access via $page.props.currentUser, $page.props.flash, etc.
  inertia_share do
    {
      flash: {
        success: flash[:notice],
        error: flash[:alert]
      }
    }.tap do |shared|
      if signed_in?
        shared[:currentUser] = {
          id: Current.user.id,
          name: Current.user.name,
          username: Current.user.username,
          avatar_url: fresh_user_avatar_path(Current.user, only_path: true),
          initials: Current.user.name.split.map { |n| n[0] }.join.upcase[0, 2],
          title: Current.user.title
        }
      end
    end
  end
end
