class MessagePresenter < ApplicationPresenter
  def initialize(message, view: :default)
    @message = message
    @view = view
  end

  def as_json
    {
      id: @message.id,
      room_id: @message.room_id,
      creator_id: @message.creator_id,
      client_message_id: @message.client_message_id,
      created_at: @message.created_at,
      body: @message.body.to_s,
      plain_text_body: @message.plain_text_body,
      content_type: @message.content_type.to_s,
      attachment: attachment_json,
      creator: creator_json
    }
  end

  private

  def attachment_json
    return nil unless @message.attachment.attached?

    {
      filename: @message.attachment.filename.to_s,
      content_type: @message.attachment.content_type,
      url: Rails.application.routes.url_helpers.rails_blob_path(@message.attachment, only_path: true)
    }
  end

  def creator_json
    return nil unless @message.creator

    UserPresenter.new(@message.creator).as_json
  end
end
