class PrintsController < ApplicationController
  before_action :require_login

  def index
  	@prints = Print.where(store: current_user.store)
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: DateTime.now.to_i.to_s,
          template: "prints/print.html.slim"
      end
    end
  end

  def clean
    prints = Print.where(store: current_user.store)
    return redirect_back_data_error prints_path, "Daftar Cetak Tidak Ditemukan" if prints.nil?
    prints.delete_all
    return redirect_success prints_path, "Daftar Cetak Telah Dibersihkan"
  end

end