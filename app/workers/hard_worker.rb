class HardWorker
  # include Sidekiq::Worker

  # def perform(*args)
  # 	RequestLogger.perform_async(params[:controller], params[:action], current_user.id)
  #   # Do something
  # end
end
