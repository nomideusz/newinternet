class UserChannel < ApplicationCable::Channel
  def subscribed
    if current_user && current_user.id.to_s == params[:user_id].to_s
      stream_for current_user
    else
      reject
    end
  end
end
