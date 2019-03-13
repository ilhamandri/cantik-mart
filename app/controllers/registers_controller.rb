class RegistersController < ApplicationController
  before_action :require_login
  before_action { |controller| controller.authorize(User::ADMIN) }

  def new
  end

  def create
    @user = User.new user_params
    @user.save
    if @user.invalid?
      return redirect_to new_register_path, flash: {error: 'Email is already taken'}
    end

    redirect_to sign_in_path, flash: {success: 'Success'}
  end

  private

    def user_params
      params.require(:user).permit(:email, :password, :name, :level)
    end

end
