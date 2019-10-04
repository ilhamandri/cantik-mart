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
    loss = nil
    receivable = nil
    cash_flow = nil
    diff_stock_val_cash = 0
    desc = ""
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if feed_value.empty?
    
    feed_value.each do |value|
      retur_item = ReturItem.find_by(id: value[1])
      if retur_item.nil?
          receivable.delete
          OrderItem.where(order: order).delete_all
          order.delete
          break
      end
      accept_item = retur_item.accept_item
      next if accept_item <= 0
      if value[0] == "retur_item"
        order_qty = value[2].to_i
        if order_qty != accept_item
          value[0] = "loss"
          diff_item =  (accept_item - order_qty)
          if loss.nil?
            invoice = "LOSS-" + Time.now.to_i.to_s
            loss = Loss.create user: current_user, store: current_user.store, from_retur: true, ref_id: retur.id, total_item: diff_item, invoice: invoice
            LossItem.create item: retur_item.item, quantity: diff_item, loss: loss, description: "LOSS FROM RETUR #"+retur.invoice
          else
            loss.total_item = loss.total_item + diff_item
            loss.save!
            LossItem.create item: retur_item.item, quantity: diff_item, loss: loss, description: "LOSS FROM RETUR #"+retur.invoice
          end
        end

        if order_qty > 0
          if order.nil?
            order = Order.create supplier_id: retur.supplier_id, 
              store: current_user.store, 
              total_items: 0,
              total: 0,
              date_created: DateTime.now,
              invoice: "ORD-" + Time.now.to_i.to_s, 
              editable: false,
              user: current_user,
              from_retur: true
          end

          ord_item = Item.find_by(id: retur_item.item.id)
          OrderItem.create  quantity: order_qty, 
                            price: 0,
                            item: ord_item,
                            order: order,
                            description: "RETUR #"+retur.invoice

          retur_item.ref_id = order.id
          retur_item.nominal = order_qty
          order.total_items = order.total_items + order_qty
          order.save!
        end
        
      elsif value[0] == "cash"
        nominal_value = value[2].to_i

        return redirect_back_data_error urls, "Nominal Potong Nota > 100" if nominal_value < 100

        item = retur_item.item
        diff_stock_val_cash += (nominal_value - (item.buy * accept_item))
        if receivable.nil?
          desc = "FROM RETUR #"+retur.invoice
          receivable = Receivable.create user: current_user, store: current_user.store, nominal: nominal_value, date_created: DateTime.now, 
                        description: "RECEIVABLE "+desc, finance_type: Receivable::RETUR, deficiency:nominal_value, to_user: retur.supplier_id,
                        ref_id: urls, due_date: DateTime.now + 2.months
        else
          receivable.nominal = receivable.nominal+nominal_value
          receivable.deficiency = receivable.deficiency+nominal_value
          receivable.save!
        end
        retur_item.ref_id = receivable.id
        retur_item.nominal = nominal_value
      elsif value[0] == "loss"
        if loss.nil?
          invoice = "LOSS-" + Time.now.to_i.to_s
          Loss.create user: current_user, store: current_user.store, from_retur: true, ref_id: retur.id, total_item: accept_item, invoice: invoice
          LossItem.create item: retur_item.item, quantity: accept_item, loss: loss, description: "LOSS FROM RETUR #"+retur.invoice
        else
          loss.total_item = loss.total_item + retur_item.quantity
          loss.save!
          LossItem.create item: retur_item.item, quantity: accept_item, loss: loss, description: "LOSS FROM RETUR #"+retur.invoice
        end
        retur_item.ref_id = receivable.id
      end

      retur_item.feedback = value[0]
      retur_item.save!
    end
    if diff_stock_val_cash != 0
      if diff_stock_val_cash > 0
        invoice = " IN-"+Time.now.to_i.to_s
        cash_flow_in = CashFlow.create user: current_user, store: current_user.store, nominal: diff_stock_val_cash, date_created: DateTime.now, description: desc, 
                      finance_type: CashFlow::INCOME, invoice: invoice
      else
        invoice = " OUT-"+Time.now.to_i.to_s
        cash_flow_in = CashFlow.create user: current_user, store: current_user.store, nominal: diff_stock_val_cash, date_created: DateTime.now, description: desc, 
                      finance_type: CashFlow::INCOME, invoice: invoice
      end
      binding.pry
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
        
        array << item_r[1].values
      end
      array
    end
end
