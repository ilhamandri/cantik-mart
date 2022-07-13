class ApplicationController < ActionController::Base
  include Clearance::Controller
  include PublicActivity::StoreController 
  before_action :screening
  
  protected
    def authorize *authorized_level
      return not_found_path unless authorized_level.include? current_user.level
    end

    def not_authorize *level
      return not_found_path if level.include? current_user.level
    end

    def validate_access_only methods
      return methods.include?(action_name.to_sym)
    end

    def screening
      return if current_user.nil?
      return not_found_path if !current_user.active
      authorization
    end

    def redirect_back_data_error current_path, message
      redirect_back fallback_location: current_path, flash: { error: message }
    end

    def redirect_success current_path, message
      redirect_to current_path, flash: { success: message }
    end

    def authorization
      return if current_user.level == "owner" || current_user.level == "super_admin"

      return if ['confirm_feedback','session','received', 'pays', 'errors', 'sign_in', 'sign_out'].any? { |word| request.original_fullpath.include?(word) }

      extracted_path = Rails.application.routes.recognize_path(request.original_url)
      controller_name = extracted_path[:controller].to_sym
      method_name = extracted_path[:action].to_sym
      accessible = authentication controller_name, method_name
      redirect_to root_path, flash: { error: 'Tidak memiliki hak akses' } if !accessible
      return
    end

    def authentication controller_name, method_name

      controller = Controller.find_by(name: controller_name.to_s)
      return true if ["notifications", "absents"].include? controller.name

      find_method = ControllerMethod.find_by(controller: controller, name: method_name.to_s)
      get_access = UserMethod.find_by(user_level: current_user.level, controller_method: find_method)
      return true if get_access.present?
      return false
    end

    def set_notification from_user, to_user, m_type, message, link
      Notification.create from_user: from_user, to_user: to_user, m_type: m_type,
        message: message, link: link, date_created: DateTime.now
    end
end
