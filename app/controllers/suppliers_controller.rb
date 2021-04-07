class SuppliersController < ApplicationController
  before_action :require_login
  
  def index
    @suppliers = Supplier.order("name ASC").page param_page
    @suppliers = @suppliers.where(supplier_type: 0)
    @search = "Pencarian "
    if params[:search].present?
      @search += "Suplier '"+params[:search]+"'"
      search = "%"+params[:search].downcase+"%"
      @suppliers = @suppliers.where("lower(name) like ? OR phone like ?", search, search)
    else
      @search += "semua data"
    end
    @params = params

    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        @suppliers = Supplier.order("name ASC")
        @suppliers = @suppliers.where(supplier_type: 0)
        @search = "Pencarian "
        if new_params["search"].present?
          @search += "Suplier '"+new_params["search"]+"'"
          search = "%"+new_params["search"].downcase+"%"
          @suppliers = @suppliers.where("lower(name) like ? OR phone like ?", search, search)
        else
          @search += "semua data"
        end
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "suppliers/print.html.slim"
      end
    end
  end

  def show
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless params[:id].present?
    id = params[:id]
    id = Supplier.first.id if params[:id] == "0"
    @supplier = Supplier.find_by_id id
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless @supplier.present?
    
    respond_to do |format|
      format.html
        @orders = Order.where(supplier: @supplier).order("created_at DESC")
        @order_items = OrderItem.where(order: @orders.pluck(:id)).page param_item_page
        @datas = @order_items.select(:item_id, :quantity).group(:item_id).sum(:quantity).sort_by(&:last).reverse
        @orders = @orders.page param_order_page
        @supplier_items = SupplierItem.where(supplier: @supplier).page param_item_page
        @debts = Debt.where(finance_type: Debt::ORDER, supplier: @supplier).where("deficiency > 0")
        @total_debt = @debts.sum(:deficiency)
        @receivables = Receivable.where(finance_type: Receivable::RETUR, to_user: @supplier.id).where("deficiency > 0")
        @total_receivable = @receivables.sum(:deficiency)

      format.pdf do
        @order_items = OrderItem.where(order: Order.where(supplier: @supplier).pluck(:id)).select(:item_id, :quantity)
        @inventories = @order_items.group(:item_id).sum(:quantity)
        @inventories = @inventories.sort_by(&:last).reverse
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "suppliers/print_supplier_items.html.slim"
      end
    end
    
  end

  def print_debt_receive
    respond_to do |format|
      format.html
      format.pdf do
        @suppliers = Supplier.order("name ASC")
        @suppliers = @suppliers.where(supplier_type: 0)
        @search = "Daftar Hutang Piutang Semua Supplier"
        @type = "debtlist"
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "suppliers/print.html.slim"
      end
    end
  end

  def new
  end

  def create
    supplier = Supplier.new supplier_params
    supplier.name = params[:supplier][:name].camelize
    supplier.address = params[:supplier][:address].camelize
    return redirect_back_data_error new_supplier_path, "Data Supplier Tidak Ditemukan" if supplier.invalid?
    supplier.save!
    supplier.create_activity :create, owner: current_user
    return redirect_success suppliers_path, "Data Supplier - " + supplier.name + " - Berhasil Ditambahkan"
  end

  def edit
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless params[:id].present?
    @supplier = Supplier.find_by_id params[:id]
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless @supplier.present?
  end

  def update
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless params[:id].present?
    supplier = Supplier.find_by_id params[:id]
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless supplier.present?
    supplier.assign_attributes supplier_params
    supplier.name = params[:supplier][:name].camelize
    supplier.address = params[:supplier][:address].camelize
    changes = supplier.changes
    supplier.save! if supplier.changed?
    supplier.create_activity :edit, owner: current_user, parameters: changes
    return redirect_success supplier_path(id: supplier.id), "Data Supplier - " + supplier.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan" unless params[:id].present?
    supplier = Supplier.find_by_id params[:id]
    return redirect_back_data_error new_supplier_path, "Data Supplier Tidak Ditemukan" unless supplier.present?
    if supplier.supplier_items.present? || supplier.orders.present? 
      return redirect_back_data_error suppliers_path, "Data Supplier Tidak Ditemukan"
    else
      supplier.destroy
      return redirect_success suppliers_path, "Data Supplier - " + supplier.name + " - Berhasil Dihapus" 
    end
  end

  private
    def supplier_params
      params.require(:supplier).permit(
        :name, :address, :phone
      )
    end

    def param_page
      params[:page]
    end

    def param_item_page
      params[:item_page]
    end

    def param_order_page
      params[:order_page]
    end

end
