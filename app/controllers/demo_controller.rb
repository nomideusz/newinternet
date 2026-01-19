class DemoController < ApplicationController
  layout "inertia"

  skip_before_action :require_authentication

  def show
    render inertia: "Demo", props: {
      message: "Hello from Rails + Inertia + Svelte!",
      timestamp: Time.current.to_s,
      user: Current.user ? { name: Current.user.name } : nil
    }
  end
end
