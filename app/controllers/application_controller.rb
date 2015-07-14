# Main application controller
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :log_to_kafka

  private

  def log_to_kafka
    if KAFKA
      message = Kafka::Message.new(request.fullpath)
      KAFKA.push([message])
    else
      logger.warn("Kafka is not defined")
    end
  end
end
