module ApplicationHelper
	
	
	def wicked_pdf_image_tag_for_public(img, options={})
    	if img[0] == "/"        
      		new_image = img.slice(1..-1)
      		image_tag "file://#{Rails.root.join('public', new_image)}", options
	    else        
	        image_tag img
	    end
  	end   

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

	def isStockAdmin
		return false if current_user.nil?
		return true if isAdmin
		return true if ["stock_admin"].include? current_user.level
		return false
	end

	def isFinance
		return false if current_user.nil?
		return true if isAdmin
		return true if ["finance"].include? current_user.level
		return false
	end

	def isSuperVisi
		return false if current_user.nil?
		return true if isAdmin
		return true if ["super_visi"].include? current_user.level
		return false
	end

	def isLevel levels
		return false if current_user.nil?
		return true if isAdmin
		return true if levels.include? current_user.level
		return false
	end

	def isCandyDream 
		return false if current_user.nil?
		return true if ["super_admin", "owner", "developer", "candy_dream", "finance"].include? current_user.level
		return false
	end
end
