class Api::V1::Conversations::CustomAttributesController < Api::BaseController
  skip_before_action :authenticate_user!
  before_action :set_conversation

  def show
    render json: @conversation.custom_attributes || {}
  end

  def update
    @conversation.custom_attributes ||= {}
    @conversation.custom_attributes.merge!(custom_attributes_params[:custom_attributes])
    @conversation.save!
    render json: @conversation
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def custom_attributes_params
    params.permit(custom_attributes: {})
  end
end
