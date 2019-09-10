class PaysController < ApplicationController
  before_action :require_login

  def new
  	@data = nil
  	return redirect_back_data_error cash_flows_path, "Data tidak valid" unless params[:id].present? ||  params[:type].present?
  	if params[:type] == "debt"
  		@type = "debt"
  		@data = Debt.find_by(id: params[:id])
  	elsif params[:type] == "receivable"
  		@type = "receivable"
  		@data = Receivable.find_by(id: params[:id])
  	else
  		return redirect_back_data_error cash_flows_path, "Data tidak valid"
  	end
  	return redirect_back_data_error cash_flows_path, "Data tidak valid" if @data.nil?
  end

  def create
  	@data = nil
  	return redirect_back_data_error cash_flows_path, "Data tidak valid" unless params[:pay][:id].present? ||  params[:pay][:type].present?
  	if params[:pay][:type] == "debt"
  		@type = "debt"
  		@data = Debt.find_by(id: params[:pay][:id])
  	elsif params[:pay][:type] == "receivable"
  		@type = "receivable"
  		@data = Receivable.find_by(id: params[:pay][:id])
  	else
  		return redirect_back_data_error cash_flows_path, "Data tidak valid" if @data.nil?
  	end
  	return redirect_back_data_error cash_flows_path, "Data tidak valid" if @data.nil?

  	pay_nominal = params[:pay][:pay_nominal].to_i
  	f_type = params[:pay][:type]
  	return redirect_back_data_error cash_flows_path, "Data tidak valid" if pay_nominal.nil?
  	if pay_nominal <= 100 || pay_nominal > @data.deficiency
  		return redirect_back_data_error cash_flows_path, "Nominal harus lebih besar dari 100 atau kurang dari jumlah yang ditentukan"
  	end
  	@data.deficiency = @data.deficiency.to_i - pay_nominal.to_i
  	user = current_user
  	store = current_user.store
  	date_created = DateTime.now
  	inv_number = Time.now.to_i.to_s
  	if f_type == "debt"
  		invoice = " OUT-"+inv_number+"-1"
	    cash_flow = CashFlow.create user: user, store: store, nominal: pay_nominal, date_created: date_created, description: "Pembayaran Hutang - "+@data.description, 
	                finance_type: CashFlow::OUTCOME, invoice: invoice, payment: "debt", ref_id: @data.id
	    store.cash = store.cash - pay_nominal
	    store.save!
	    cash_flow.create_activity :create, owner: current_user   
	    @data.save!
  	elsif f_type == "receivable"
  		invoice = " IN-"+inv_number+"-1"
	    cash_flow = CashFlow.create user: user, store: store, nominal: pay_nominal, date_created: date_created, description: "Pembayaran Piutang - "+@data.description, 
	                      finance_type: CashFlow::INCOME, invoice: invoice, payment: "receivable", ref_id: @data.id
	    store.cash = store.cash + pay_nominal
	    store.save!
	    cash_flow.create_activity :create, owner: current_user 
	    @data.save!   
  	else
  		return redirect_back_data_error cash_flows_path, "Data tidak valid"
  	end		
  	return redirect_success cash_flows_path, "Pembayaran berhasil disimpan"
  end
end