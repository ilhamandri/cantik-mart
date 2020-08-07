class TestsController < ApplicationController
  before_action :require_login

  def index
  	@tests = Test.page param_page
  end

  def show
  	return redirect_back_data_error tests_path, "Date tidak ditemukan" if params[:id].nil?
  	@test = Test.find_by(id: params[:id])
  	return redirect_back_data_error tests_path, "Data tidak ditemukan" if @test.nil?
  end

  def new
  	@stores = Store.all
  end

  def create
  	test = Test.new test_params
  	return redirect_back_data_error new_test_path, "Data error" if test.invalid?
  	test.save!
  	test.create_activity :create, owner: current_user
  	return redirect_success test_path(id: test.id), "Data disimpan"
  end

  def destroy
  	return redirect_back_data_error tests_path, "Data tidak ditemukan" if params[:id].nil?
  	test = Test.find_by(id: params[:id])
  	return redirect_back_data_error tests_path, "Data tidak ditemukan" if test.nil?
  	test.destroy
  	return redirect_success tests_path, "Data " + test.name + " dihapus"
  end

  def edit
  	return redirect_back_data_error tests_path, "Date tidak ditemukan" if params[:id].nil?
  	@test = Test.find_by(id: params[:id])
  	return redirect_back_data_error tests_path, "Data tidak ditemukan" if @test.nil?
  	@stores = Store.all
  end

  def update
  	return redirect_back_data_error tests_path, "Date tidak ditemukan" if params[:id].nil?
  	@test = Test.find_by(id: params[:id])
  	return redirect_back_data_error tests_path, "Data tidak ditemukan" if @test.nil?
  	@test.assign_attributes test_params
  	return redirect_success test_path(id: @test.id), "Data tidak ada perubahan" if !@test.changed
  	@test.save!
  	changes = @test.changes
  	@test.create_activity :edit, owner: current_user, params: changes
  	return redirect_success test_path(id: @test.id), "Data disimpan" if !@test.changed
  end

  private
    def test_params
      params.require(:test).permit(
        :name, :store_id
      )
    end

    def param_page
      params[:page]
    end
end