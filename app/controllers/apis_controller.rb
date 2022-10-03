class ApisController < ApplicationController
  def index
    api_type = params[:api_type]
    if api_type == "item"
      get_item params
    elsif api_type == "order"
      get_item_order params
    elsif api_type == "trx"
      get_item_trx params
    elsif api_type == "transfer"
      get_item_trf params
    elsif api_type == "send_back"
      get_item_send_back params
    elsif api_type == "member"
      get_member params
    elsif api_type == "voucher"
      get_voucher params
    elsif api_type == "get_user_salary"
      get_user_salary params
    elsif api_type == "get_notification"
      get_notification params
    elsif api_type == "update_notification"
      update_notification params
    elsif api_type == "home"
      get_home params 
    elsif api_type == "sync"
      get_sync params
    elsif api_type == "update_item_id"
      get_update_item 
    end   
  end

  def get_update_item
    items = Item.all.pluck(:id, :code)
    render :json => items.map(&:reverse).to_h
  end

  def get_sync 
    json_result = []
    store_id = params[:id]
    sync_date = params[:target]
    return render :json => json_result if store_id.empty? || sync_date.empty?
    sync_date = sync_date.to_datetime.localtime.beginning_of_day
    end_date = sync_date.end_of_day
    trxs = Transaction.where(store_id: store_id, created_at: sync_date..end_date)

    complains = Complain.where(created_at: sync_date..end_date, store_id: store_id)
    complain_nominal = trxs.where(from_complain: true).sum(:grand_total).to_i - complains.sum(:nominal).to_i

    return render :json => json_result if trxs.empty?
    json_result << trxs.where(from_complain: false).count
    json_result << TransactionItem.where(created_at: sync_date..end_date, store_id: store_id, transaction_id: trxs.where(from_complain: false).pluck(:id)).sum(:total).to_i 
    json_result << complains.count
    json_result << complain_nominal
    response.headers['Access-Control-Allow-Origin'] = '*'   
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Headers'] = 'accept, content-type'
    response.headers['X-XSS-Protection'] = 'none'
    render :json => json_result 
  end 

  def get_home params
    url = URI.parse('http://localhost:3030/api/home')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    datas = JSON.parse(res.body)
    render :json => datas
  end

  def get_user_salary params
    json_result = []
    user_id = params[:id].squish
    return render :json => json_result unless user_id.present?
    user = User.find_by(id: user_id)
    if user.present? 
      user_debt = Receivable.where("deficiency > 0").where(finance_type: Receivable::EMPLOYEE).where(to_user: user_id).sum(:deficiency)
      kasbon = Kasbon.find_by(user: user)
      nominal = 0
      nominal = kasbon.nominal if kasbon.present?
      json_result << view_context.number_with_delimiter(user.salary, delimiter: ".", separator: ",")
      json_result << view_context.number_with_delimiter(user_debt.to_i, delimiter: ".", separator: ",")
      json_result << view_context.number_with_delimiter(nominal.to_i, delimiter: ".", separator: ",")
    end
    render :json => json_result
  end

  def get_voucher params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    voucher = Voucher.find_by(voucher_code: search.to_i)
    if voucher.present?
      epoint = voucher.exchange_point
      json_result << [epoint.name, epoint.quantity]
    end
    render :json => json_result
  end

  def get_notification params
    json_result = []
    unread_notifications = Notification.where(to_user: current_user, read: 0).order("date_created DESC")
    notifications = Notification.where(to_user: current_user, read: 0).order("date_created DESC").limit(5)

    json_result << [DateTime.now, unread_notifications.count]
    notifications.each do|notification|
      json_result << [notification.from_user.name, notification.date_created, notification.message, notification.m_type, notification.link, notification.read]
    end
    render :json => json_result
  end

  def update_notification params
    json_result = []
    Notification.where(to_user: current_user, read: 0).order("date_created DESC").update_all(read: 1)
    notifications = Notification.where(to_user: current_user).order("date_created DESC").limit(5)

    json_result << [DateTime.now, 0]
    notifications.each do|notification|
      json_result << [notification.from_user.name, notification.date_created, notification.message, notification.m_type, notification.link, notification.read]
    end
    render :json => json_result
  end

  def get_member params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    search = search.gsub(/\s+/, "")
    members = Member.where('lower(name) like ? OR card_number = ?', "%"+search.downcase+"%", search)
    members.each do|member|
      json_result << [member.card_number, member.name, member.address, member.phone]
    end
    render :json => json_result
  end

  def get_item params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    search = search.gsub(/\s+/, "")
    items = Item.where('lower(name) like ?', "%"+search.downcase+"%").pluck(:id)
    item_stores = StoreItem.where(store_id: current_user.store.id, item: items)
    return render :json => json_result unless item_stores.present?
    item_stores.each do |item_store|
      item = []
      item << item_store.item.code
      item << item_store.item.name
      item << item_store.item.item_cat.name
      item << item_store.item.sell
      json_result << item
    end
    render :json => json_result
  end

  def get_item_order params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    search = search.gsub(/\s+/, "")
    find_item = Item.find_by(code: search)
    return render :json => json_result unless find_item.present?
    item = []
    item << find_item.code
    item << find_item.name
    item << find_item.item_cat.name
    item << find_item.buy.round
    item << find_item.id
    item << find_item.sell

    if current_user.store.store_type == "retail"
      if find_item.local_item 
        json_result << item
      end
    else
      json_result << item
    end
    render :json => json_result
  end

  def get_item_trf params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    search = search.gsub(/\s+/, "")
    find_item = Item.find_by(code: search)
    return render :json => json_result unless find_item.present?
    
    return render :json => json_result if find_item.local_item
    
    target_store = Store.find_by(id: params[:target].to_i)
    store_item = StoreItem.find_by(store: target_store, item: find_item)
    stock = 0
    stock = store_item.stock if store_item.present?
    item = []
    item << find_item.code
    item << find_item.name
    item << find_item.item_cat.name
    item << find_item.buy.round
    item << find_item.id
    item << find_item.sell
    item << stock 

    json_result << item

    render :json => json_result
  end

  def get_item_send_back params
    json_result = []
    search = params[:search].squish
    return render :json => json_result unless search.present?
    search = search.gsub(/\s+/, "")
    find_item = Item.find_by(code: search)
    return render :json => json_result unless find_item.present?
    
    return render :json => json_result if find_item.local_item
    
    item = []
    item << find_item.code
    item << find_item.name
    item << find_item.id
    json_result << item

    render :json => json_result
  end

  def get_item_trx params
    json_result = []
    qty = params[:qty]

    member = nil
    if params[:member].present?
      member = Member.find_by(card_number: params[:member])
    end
    member = nil

    search = params[:search].squish
    return render :json => json_result unless search.present?
    return render :json => json_result unless qty.present?
    return render :json => json_result if qty.to_f <= 0
    search = search.gsub(/\s+/, "")
    item_id = Item.find_by(code: search)
    item_store = StoreItem.find_by(store_id: current_user.store.id, item: item_id)
    return render :json => json_result unless item_store.present?

    item = []
    item << item_store.item.code
    item << item_store.item.name
    item << item_store.item.item_cat.name
    curr_item = item_store.item
    qty = qty.to_i
    grocer_price = nil 
    grocer_price = curr_item.grocer_items.where("min <= ?", qty) if qty.to_i > 1
    if grocer_price.present?
      find_price = grocer_price.where('max >= ? AND min <= ?', qty, qty).order("max ASC")
      if find_price.present?
        price = find_price.first
        disc = find_price.first.discount
        disc = (disc * price.price) / 100 if disc <= 100
        if member.present?
          disc = find_price.first.discount
          disc = (disc * price.member_price) / 100 if disc <= 100
          item << price.member_price + disc
        else
          item << price.price + disc
        end
        item << disc
      else
        # LEBIH DARI JUMLAH HARGA GROSIR YANG DITENTUKAN
        find_price = grocer_price.where('max <= ? ', qty).order("max DESC")
        if find_price.present?
          price = find_price.first
          disc = find_price.first.discount
          disc = (disc * price.price) / 100 if disc <= 100
          if member.present?
            disc = find_price.first.discount
            disc = (disc * price.member_price) / 100 if disc <= 100
            item << price.member_price + disc
          else
            item << price.price + disc
          end
          item << disc
        else
          find_price = grocer_price.order("max ASC")
          price = find_price.first.price
          disc = find_price.first.discount
          disc = (disc * price) / 100 if disc <= 100
          item << price + disc
          item << disc
        end
      end
    else
      disc = item_id.discount
      disc = (disc * item_id.sell) / 100 if disc <= 100
      if member.present?
        disc = item_id.discount
        disc = (disc * item_id.sell_member) / 100 if disc <= 100
        item << item_id.sell_member + disc
      else
        item << item_id.sell + disc
      end
      item << disc
    end

    item << item_id.id


    promo = Promotion.where(buy_item: item_id).where("start_promo <= ? AND end_promo >= ? AND buy_quantity <= ?", DateTime.now, DateTime.now, qty).first
    if promo.present?
      hit_promo = qty.to_i / promo.buy_quantity
      item << promo.promo_code
      item << promo.free_item.code
      item << promo.free_item.name
      item << hit_promo * promo.free_quantity
    end
    
    json_result << item
    render :json => json_result
  end

end