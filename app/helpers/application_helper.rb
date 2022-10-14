module ApplicationHelper
	def isAdmin
		return false if current_user.nil?
		return true if ["super_admin", "owner", "developer"].include? current_user.level
		return false
	end

	def buttonAccess controller_name, action_name
		return false if current_user.nil?
		return true if isAdmin
		can_access = false
		controllers = Controller.find_by(name: controller_name)
		if controllers.present?
			can_access = controllers.controller_methods.find_by(name: action_name).user_methods.pluck(:user_level).include? current_user.level
		end
		return true if can_access
		return false
	end

	def isDeveloper
		return false if current_user.nil?
		return true if current_user.level=="developer"
		return false
	end

	def isFinance
		return false if current_user.nil?
		return true if ["super_admin", "owner", "developer", "finance"].include? current_user.level
		return false
	end
end
