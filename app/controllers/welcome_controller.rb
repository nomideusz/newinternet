class WelcomeController < ApplicationController
  include SidebarSupport

  layout "inertia", only: :show

  def show
    if Current.user.rooms.any?
      redirect_to room_url(last_room_visited)
    else
      load_sidebar_data
      render inertia: "Welcome/Show", props: {
        currentUser: {
          id: Current.user.id,
          name: Current.user.name,
          avatar_url: fresh_user_avatar_path(Current.user)
        },
        sidebar: @sidebar_props
      }
    end
  end
end
