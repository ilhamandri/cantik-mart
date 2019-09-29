class PromotionsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search params
    @search = filter[0]
    @promotions = filter[1]
    @params = params.to_s
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @promotions = filter[1]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "promotions/print_all.html.slim"
      end
    end
  end

  def create
    buy_code = params[:promotion][:buy_item]
    free_code = params[:promotion][:free_item]
    start_date = params[:promotion][:start_promo]
    end_date = params[:promotion][:end_promo]

    buy_item = Item.find_by(code: buy_code)
    free_item = Item.find_by(code: free_code)
    promo_code = "PROMO-"+DateTime.now.to_i.to_s

    return redirect_back_data_error new_promotion_path, "Data barang beli dengan kode - "+buy_code+" tidak ditemukan" if buy_item.nil?
    return redirect_back_data_error new_promotion_path, "Data barang gratis dengan kode - "+free_code+" tidak ditemukan" if free_item.nil?
    return redirect_back_data_error new_promotion_path, "Data mulai promo tidak valid" if start_date.nil?
    return redirect_back_data_error new_promotion_path, "Data selesai promo tidak valid" if end_date.nil?



    promotion = Promotion.new promotion_params
    promotion.promo_code = promo_code
    promotion.user = current_user
    promotion.start_promo = start_date.to_datetime.beginning_of_day
    promotion.end_promo = end_date.to_datetime.end_of_day
    promotion.buy_item = buy_item
    promotion.free_item = free_item

    return redirect_back_data_error new_promotion_path, "Data tidak lengkap. Silahkan periksa kembali." if promotion.invalid?
    promotion.save!
    promotion.create_activity :create, owner: current_user
    return redirect_success promotions_path, promo_code + " - Berhasil Disimpan"
  end

  def destroy
    return redirect_back_data_error promotions_path, "Data Promo Tidak Ditemukan" if params[:id].nil?
    promotion = Promotion.find_by(id: params[:id])
    return redirect_back_data_error promotions_path, "Data Promo Tidak Ditemukan" if promotion.nil?
    promo_code = promotion.promo_code
    promotion.destroy
    return redirect_success promotions_path, "Data Promo - " + promo_code + " - Telah Dihapus"
  end

  def show
    return redirect_back_data_error promotions_path, "Data Promo Tidak Ditemukan" unless params[:id].present?
    @promotion = Promotion.find_by(id: params[:id])
    return redirect_back_data_error promotions_path, "Data Promo Tidak Ditemukan" unless @promotion.present?
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @promotion.promo_code,
          layout: 'pdf_layout.html.erb',
          template: "orders/print.html.slim"
      end
    end
  end

  private
    def promotion_params
      params.require(:promotion).permit(
        :buy_quantity, :free_quantity, :start_promo, :end_promo
      )
    end

  	def param_page
  		params[:page]
  	end

  	def filter_search params
  	  results = []
      search_text = "Pencarian "
      filters = Promotion.page param_page

     
      end_date = DateTime.now.to_date + 1.day
      start_date = DateTime.now.to_date - 1.month
      end_date = params["end_date"].to_date.to_s if params["end_date"].present?
      start_date = params["date_from"].to_date.to_s if params["date_from"].present?
      search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
      filters = filters.where("created_at >= ? AND created_at <= ?", start_date, end_date)

      if params["order_by"] == "asc"
        search_text+= "secara menaik"
        filters = filters.order("created_at ASC")
      else
        filters = filters.order("created_at DESC")
        search_text+= "secara menurun"
      end

      results << search_text
      results << filters
      return results
  	end

end