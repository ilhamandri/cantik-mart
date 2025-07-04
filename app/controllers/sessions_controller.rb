class SessionsController < Clearance::SessionsController
	after_action :update_user

	def new
	end

	def update_user
		if ["/session"].include? request.fullpath
			device = browser.meta[3] + " (" + browser.meta[2] + ")"
			UserDevice.create user: current_user, ip: request.ip, device: device, action: "IN"
		end
	end

	def log_out
		device = browser.meta[3] + " (" + browser.meta[2] + ")"
		UserDevice.create user: current_user, ip: request.ip, device: device, action: "OUT"
		destroy
	end
end
