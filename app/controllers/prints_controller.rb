class PrintsController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
  	@prints = Print.where(store: current_user.store).includes(:item)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: DateTime.now.to_i.to_s,
          show_as_html: false,
          template: "prints/print", 
          formats: [:html], 
          disposition: :inline
      end
    end
  end

  def clean
    prints = Print.where(store: current_user.store)
    return redirect_back_data_error prints_path, "Daftar Cetak Tidak Ditemukan" if prints.nil?
    prints.delete_all
    return redirect_success prints_path, "Daftar Cetak Telah Dibersihkan"
  end

  def delete_item
    id = params[:id]
    return redirect_back_data_error prints_path, "Daftar Cetak Tidak Ditemukan" if id.nil?
    print_data = Print.find_by_id id
    return redirect_back_data_error prints_path, "Daftar Cetak Tidak Ditemukan" if print_data.nil?
    item_name = print_data.item.name
    print_data.destroy
    if params[:f] == "1"
      return redirect_success items_path, item_name+" DIHAPUS dari Daftar Cetak"
    else
      return redirect_success prints_path, item_name+" DIHAPUS dari Daftar Cetak"
    end
  end

end