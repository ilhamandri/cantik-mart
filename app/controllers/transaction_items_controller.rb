class TransactionItemsController < ApplicationController
  before_action :require_login
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  def index
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if params[:id].nil?
    @transaction_items = TransactionItem.where(transaction_id: params[:id]).page param_page
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end

  private
    def param_page
       params[:page]
    end
end
