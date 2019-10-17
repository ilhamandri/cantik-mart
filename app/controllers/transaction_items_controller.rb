class TransactionItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
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
