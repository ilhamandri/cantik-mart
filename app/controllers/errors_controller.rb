class ErrorsController < ApplicationController

  def no_access_right
    respond_to do |format|
      format.html { render status: 403, :layout => false }
      format.json { render json: { error: "No Access Right" }, status: 403 }
    end
  end

  def not_found
    respond_to do |format|
      format.html { render status: 404, :layout => false }
      format.json { render json: { error: "Resource not found" }, status: 404 }
    end
  end

  def unacceptable
    respond_to do |format|
      format.html { render status: 422, :layout => false }
      format.json { render json: { error: "Params unacceptable" }, status: 422 }
    end
  end

  def internal_error
    respond_to do |format|
      format.html { render status: 500, :layout => false }
      format.json { render json: { error: "Internal server error" }, status: 500 }
    end
  end
end