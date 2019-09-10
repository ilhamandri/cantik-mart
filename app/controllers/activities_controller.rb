class ActivitiesController < ApplicationController
  before_action :require_login
	def index
		@models = PublicActivity::Activity.pluck(:trackable_type)
	  	@activities = PublicActivity::Activity.order("created_at desc").page param_page
		@search_text = ""
		@date_search = nil
		if params[:activity].present?
			@date_search = params[:activity][:date_search] 
			@access_levels = params[:activity][:access_levels] 
			@targets = params[:activity][:targets]
		end

		if @targets.present?
			@search_text+= @targets.to_s + " "
			@activities = @activities.where(trackable_type: @targets)
		end

		if @access_levels.present?
			int_access_levels = @access_levels.map(&:to_i)
			users = User.where(level: int_access_levels).pluck(:id)
			levels = "["
			int_access_levels.each do |level|
				levels+= User.levels.key(level).humanize 
				if level == int_access_levels.last
					levels+= "] "
				else
					levels+= ", "
				end
			end
			@activities = @activities.where(owner_id: users)
			@search_text+= " dengan hak akses " + levels
		end

		if @date_search.present?
			@activities.where("created_at >= ? AND created_at <= ? ", @date_search.to_date.beginning_of_day, @date_search.to_date.end_of_day)
			@search_text+= "pada tanggal " + @date_search.to_s
		end
		@search_text = "Pencarian "+@search_text if @search_text.size > 0
		# @activities.delete_all
	end

	def show
		return redirect_back_data_error activities_path, "Data Aktivitas Tidak Ditemukan" unless params[:id].present?
	    @activity = PublicActivity::Activity.find params[:id]
	    return redirect_back_data_error activities_path, "Data Aktivitas Tidak Ditemukan" unless @activity.present?
	end

	private
		def param_page
			params[:page]
		end

end
