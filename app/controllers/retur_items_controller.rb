class ReturItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    @retur_items = ReturItem.page param_page
    @retur_items = @retur_items.where(retur_id: params[:id])
  end

  def feedback
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" unless params[:id].present?
    @retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless @retur.present?
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if @retur.status.present?
    @retur_items = ReturItem.where(retur_id: @retur.id)
  end

  def feedback_confirmation
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless retur.present?
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if retur.status.present?
    feed_value = feedback_value
    urls = retur_path(id: retur.id)
    order = nil
    receivable = nil
    total_items = 0

    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if feed_value.empty?
    
    feed_value.each do |value|
      retur_item = ReturItem.find_by(id: value[1])
      if retur_item.nil?
          receivable.delete
          OrderItem.where(order: order).delete_all
          order.delete
          break
      end
      next if retur_item.accept_item <= 0
      if value[0] == "retur_item"
        if order.nil?
          order = Order.create supplier_id: retur.supplier_id, 
            store: current_user.store, 
            total_items: total_items,
            total: 0,
            date_created: DateTime.now,
            invoice: "ORD-" + Time.now.to_i.to_s, 
            editable: true,
            user: current_user
        end
       
        order_qty = value[2].to_i
        if order_qty == 0
          value[0] = "loss"
          next
        end
        order_qty = retur_item.accept_item if order_qty > retur_item.accept_item 
        if order_qty < retur_item.accept_item 
          buy = retur_item.item.buy if !retur_item.item.local_item
          buy = StoreItem.find_by(store: retur.store, item: retur_item.item).buy.to_f if retur_item.item.local_item
          nominal_value =  (retur_item.accept_item - order_qty) * buy
          if receivable.nil?
            receivable = Receivable.create user: current_user, store: current_user.store, nominal: nominal_value, date_created: DateTime.now, 
                        description: "RECEIVABLE FROM RETUR #"+retur.invoice, finance_type: Receivable::RETUR, deficiency:nominal_value, to_user: retur.supplier_id,
                        ref_id: urls, due_date: DateTime.now + 2.months
          else
            receivable.nominal += receivable.nominal+nominal_value
            receivable.deficiency += receivable.deficiency+nominal_value
            receivable.save!
          end
        end
        ord_item = Item.find_by(id: retur_item.item.id)
        OrderItem.create  quantity: order_qty, 
                          price: 0,
                          item: ord_item,
                          order: order,
                          description: "RETUR #"+retur.invoice

        retur_item.ref_id = order.id
        retur_item.nominal = order_qty
        total_items+=1
        order.update(total_items: total_items)

      elsif value[0] == "cash"
        nominal_value = value[2].to_i

        return redirect_back_data_error urls, "Nominal Potong Nota > 100" if nominal_value < 100
        if receivable.nil?
          receivable = Receivable.create user: current_user, store: current_user.store, nominal: nominal_value, date_created: DateTime.now, 
                        description: "RECEIVABLE FROM RETUR #"+retur.invoice, finance_type: Receivable::RETUR, deficiency:nominal_value, to_user: retur.supplier_id,
                        ref_id: urls, due_date: DateTime.now + 2.months
        else
          receivable.nominal += receivable.nominal+nominal_value
          receivable.deficiency += receivable.deficiency+nominal_value
          receivable.save!
        end
        retur_item.ref_id = receivable.id
        retur_item.nominal = nominal_value
      end
      retur_item.feedback = value[0]
      retur_item.save!
    end
    retur.status = Time.now
    retur.save
    return redirect_success urls, "Data Retur " + retur.invoice + " Telah Dikonfirmasi"
  end

  def show
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    @retur_item = ReturItem.find_by_id params[:id]
    return redirect_back_data_error new_retur_item_path, "Data Retur Tidak Ditemukan" unless @retur_item.present?
  end

  private
    def param_page
      params[:page]
    end

    def feedback_value
      array = []
      params[:retur][:retur_items].each do |item_r|
        item_d = item_r[1]
        ret_item = ReturItem.find_by(id: item_d["item_id"])
        item = ret_item.item
        nominal = item_d["nominal"].to_i

        if item_d["feedback"] == "cash"
          buy = item.buy if !item.local_item
          buy = StoreItem.find_by(item: item, store: ret_item.retur.store).buy if item.local_item

          qty = ret_item.accept_item.to_i

          totals = qty * buy

          if totals != nominal
            return []
          end
        end
        array << item_r[1].values
      end
      array
    end
end
