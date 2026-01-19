class Users::PushSubscriptionsController < ApplicationController
  layout "inertia", only: :index

  before_action :set_push_subscriptions

  def index
    render inertia: "Users/PushSubscriptions/Index", props: {
      page: { title: "Push notification subscriptions" },
      pushSubscriptions: @push_subscriptions.map { |sub| push_subscription_json(sub) },
      cancelUrl: last_room_visited ? room_path(last_room_visited) : root_path,
      currentUser: UserPresenter.new(Current.user, view: :minimal).as_json
    }
  end

  def create
    if subscription = @push_subscriptions.find_by(push_subscription_params)
      subscription.touch
    else
      @push_subscriptions.create! push_subscription_params.merge(user_agent: request.user_agent)
    end

    head :ok
  end

  def destroy
    @push_subscriptions.destroy_by(id: params[:id])
    redirect_to user_push_subscriptions_url
  end

  private
    def set_push_subscriptions
      @push_subscriptions = Current.user.push_subscriptions
    end

    def push_subscription_params
      params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
    end

    def push_subscription_json(subscription)
      agent = UserAgent.parse(subscription.user_agent)
      {
        id: subscription.id,
        endpoint: subscription.endpoint,
        browser: agent.browser,
        version: agent.version.to_s,
        platform: agent.platform
      }
    end
end
