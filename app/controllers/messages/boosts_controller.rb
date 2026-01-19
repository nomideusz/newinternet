class Messages::BoostsController < ApplicationController
  before_action :set_message

  def index
    respond_to do |format|
      format.html
      format.json { render json: @message.boosts }
    end
  end

  def new
  end

  def create
    @boost = @message.boosts.create!(boost_params)

    broadcast_create

    respond_to do |format|
      format.html { redirect_to message_boosts_url(@message) }
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  def destroy
    @boost = Current.user.boosts.find(params[:id])
    @boost.destroy!

    broadcast_remove

    respond_to do |format|
      format.html { redirect_to message_boosts_url(@message) }
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  private
    def set_message
      @message = Current.user.reachable_messages.find(params[:message_id])
    end

    def boost_params
      params.require(:boost).permit(:content)
    end

    def broadcast_create
      @boost.broadcast_append_to @boost.message.room, :messages,
        target: "boosts_message_#{@boost.message.client_message_id}", partial: "messages/boosts/boost", attributes: { maintain_scroll: true }
    end

    def broadcast_remove
      @boost.broadcast_remove_to @boost.message.room, :messages
    end
end
