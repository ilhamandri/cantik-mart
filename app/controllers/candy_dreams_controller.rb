class CandyDreamsController < ApplicationController
  before_action :require_login

  def index
    @search = "c"
    @transactions  = Transaction.where("lower(invoice) like ?",  "%#{@search}%").order('created_at DESC').page param_page
  end

  def show
    return redirect_back_data_error candy_dreams_path, "Data tidak ditemukan" if params[:id].nil?
    @transaction = Transaction.find_by(id: params[:id])
    return redirect_back_data_error candy_dreams_path, "Data tidak ditemukan" if @transaction.nil?

    respond_to do |format|
      format.html do
      end
      format.pdf do
        @recap_type = "invoice"
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "candy_dreams/invoice.html.slim"
      end
    end
  end

  private
    def param_page  
      params[:page]
    end

end