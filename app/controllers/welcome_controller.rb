class WelcomeController < ApplicationController
  layout "inertia", only: :show

  def show
    if Current.user.rooms.any?
      redirect_to room_url(last_room_visited)
    else
      render inertia: "Welcome/Show", props: {
        page: { bodyClass: "sidebar" }
      }
    end
  end
end
