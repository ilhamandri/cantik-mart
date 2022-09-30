module ApplicationHelper
	def isAdmin
		return true if ["super_admin", "owner"].include? current_user.level
		return false
	end

	def buttonAccess controller_name, action_name
		return true if isAdmin
		can_access = Controller.find_by(name: controller_name).controller_methods.find_by(name: action_name).user_methods.pluck(:user_level).include? current_user.level
		return true if can_access
		return false
	end
end
