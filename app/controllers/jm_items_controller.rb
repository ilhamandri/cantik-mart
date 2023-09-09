class JmItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  before_action :screening
  require 'apriori'
  
  def index
    @items = JmItem.all
  end

  def new
  end

  def create
    code = params[:jm_item][:code]
    code = "-" if code == ""
    item = JmItem.new 
    item.code = code.gsub(" ", "")
    item.name = params[:jm_item][:name]
    item.sell = params[:jm_item][:sell]
    item.save!
    urls = jm_items_path id: item.id
    return redirect_success urls, "Data Barang Berhasil Ditambahkan"

  end

  def edit
    return redirect_back_data_error jm_items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    @item = JmItem.find_by_id params[:id]
    return redirect_back_data_error jm_items_path, "Data Barang Tidak Ditemukan" unless @item.present?
  end

  def update
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    item = JmItem.find_by_id params[:id]

    code = params[:item][:code]
    code = "-" if code == ""
    item.name = params[:item][:name]
    item.sell = params[:item][:sell]
    item.save!
    urls = jm_items_path id: item.id
    return redirect_success urls, "Data Barang - " + item.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless params[:id].present?
    item = JmItem.find_by_id params[:id]
    return redirect_back_data_error items_path, "Data Barang Tidak Ditemukan" unless item.present?
    if item.store_items.present? || item.supplier_items.present?
      return redirect_back_data_error items_path, "Data Barang Tidak Valid"
    else
      item.destroy
      return redirect_success jm_items_path, "Data Barang - " + item.name + " - Berhasil Dihapus"
    end
  end

  
end
