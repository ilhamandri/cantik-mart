# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_02_092444) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "check_in", precision: nil
    t.datetime "check_out", precision: nil
    t.datetime "overtime_in", precision: nil
    t.datetime "overtime_out", precision: nil
    t.string "work_hour", default: "0:0:0"
    t.string "overtime_hour", default: "0:0:0"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_id"
    t.index ["store_id"], name: "index_absents_on_store_id"
    t.index ["user_id"], name: "index_absents_on_user_id"
  end

  create_table "activities", force: :cascade do |t|
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner_type_and_owner_id"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient_type_and_recipient_id"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable_type_and_trackable_id"
  end

  create_table "assets", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.integer "finance_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_assets_on_store_id"
    t.index ["user_id"], name: "index_assets_on_user_id"
  end

  create_table "backups", force: :cascade do |t|
    t.string "size", null: false
    t.string "filename", null: false
    t.datetime "created", precision: nil, null: false
    t.boolean "present", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "capitals", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_capitals_on_store_id"
    t.index ["user_id"], name: "index_capitals_on_user_id"
  end

  create_table "cash_flows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.bigint "nominal", null: false
    t.integer "finance_type", default: 1, null: false
    t.datetime "date_created", precision: nil
    t.string "description"
    t.bigint "ref_id"
    t.string "invoice", default: "-", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "payment"
    t.string "tag", default: "", null: false
    t.index ["store_id"], name: "index_cash_flows_on_store_id"
    t.index ["user_id"], name: "index_cash_flows_on_user_id"
  end

  create_table "cashes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_cashes_on_store_id"
    t.index ["user_id"], name: "index_cashes_on_user_id"
  end

  create_table "complain_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "complain_id", null: false
    t.integer "quantity", null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["complain_id"], name: "index_complain_items_on_complain_id"
    t.index ["item_id"], name: "index_complain_items_on_item_id"
  end

  create_table "complains", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "total_items", null: false
    t.bigint "store_id", null: false
    t.datetime "date_created", precision: nil
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "transaction_id", null: false
    t.bigint "member_card"
    t.bigint "nominal", default: 0, null: false
    t.index ["store_id"], name: "index_complains_on_store_id"
    t.index ["transaction_id"], name: "index_complains_on_transaction_id"
    t.index ["user_id"], name: "index_complains_on_user_id"
  end

  create_table "controller_methods", force: :cascade do |t|
    t.bigint "controller_id", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["controller_id"], name: "index_controller_methods_on_controller_id"
  end

  create_table "controllers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "debts", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.bigint "deficiency", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.integer "ref_id"
    t.integer "finance_type", null: false
    t.datetime "due_date", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "supplier_id"
    t.integer "n_term", default: 1, null: false
    t.float "nominal_term", default: 0.0, null: false
    t.index ["store_id"], name: "index_debts_on_store_id"
    t.index ["supplier_id"], name: "index_debts_on_supplier_id"
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", default: "DEFAULT (NO DEPARTMENT)", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "edited_by"
  end

  create_table "discounts", force: :cascade do |t|
    t.string "code", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "discount", null: false
    t.bigint "item_id", null: false
    t.boolean "status", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_discounts_on_item_id"
  end

  create_table "exchange_points", force: :cascade do |t|
    t.integer "point", null: false
    t.string "name", null: false
    t.bigint "hit", default: 0, null: false
    t.integer "quantity", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "status", default: true, null: false
  end

  create_table "finances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.bigint "nominal", null: false
    t.integer "finance_type", default: 1, null: false
    t.datetime "date_created", precision: nil
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_finances_on_store_id"
    t.index ["user_id"], name: "index_finances_on_user_id"
  end

  create_table "grocer_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.integer "min", null: false
    t.integer "max", null: false
    t.bigint "price", null: false
    t.bigint "discount", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "member", default: false, null: false
    t.bigint "member_price", default: 0
    t.float "selisih_pembulatan", default: 0.0, null: false
    t.float "ppn", default: 0.0, null: false
    t.bigint "edited_by"
    t.index ["item_id"], name: "index_grocer_items_on_item_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_incomes_on_store_id"
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "invoice_transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "transaction_type", default: 1, null: false
    t.string "transaction_invoice", null: false
    t.bigint "nominal", default: 0, null: false
    t.datetime "date_created", precision: nil
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "description", default: "-", null: false
    t.bigint "store_id"
    t.index ["store_id"], name: "index_invoice_transactions_on_store_id"
    t.index ["user_id"], name: "index_invoice_transactions_on_user_id"
  end

  create_table "item_cats", force: :cascade do |t|
    t.string "name", default: "DEFAULT", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "department_id"
    t.boolean "use_in_point", default: true, null: false
    t.bigint "edited_by"
    t.index ["department_id"], name: "index_item_cats_on_department_id"
  end

  create_table "item_prices", force: :cascade do |t|
    t.float "buy", default: 0.0, null: false
    t.float "sell", default: 0.0, null: false
    t.bigint "item_id", null: false
    t.integer "month", default: 1, null: false
    t.integer "year", default: 2015, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_item_prices_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "code", default: "DEFAULT_CODE", null: false
    t.string "name", default: "DEFAULT_NAME", null: false
    t.bigint "stock", default: 0, null: false
    t.float "buy", default: 0.0, null: false
    t.bigint "sell", default: 0, null: false
    t.bigint "item_cat_id", null: false
    t.string "brand", null: false
    t.bigint "wholesale", default: 0, null: false
    t.bigint "box", default: 0, null: false
    t.string "image"
    t.bigint "buy_grocer", default: 0
    t.bigint "discount", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "local_item", default: false
    t.float "margin", default: 0.0
    t.datetime "price_updated", precision: nil
    t.bigint "sell_member", default: 0, null: false
    t.bigint "counter", default: 0
    t.bigint "kpi", default: 0
    t.bigint "tax", default: 0
    t.float "ppn", default: 0.0, null: false
    t.float "selisih_pembulatan", default: 0.0, null: false
    t.bigint "edited_by"
    t.index ["item_cat_id"], name: "index_items_on_item_cat_id"
  end

  create_table "jm_items", force: :cascade do |t|
    t.string "code", default: "DEFAULT_CODE", null: false
    t.string "name", default: "DEFAULT_NAME", null: false
    t.bigint "sell", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "kasbons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_kasbons_on_user_id"
  end

  create_table "loss_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "loss_id", null: false
    t.integer "quantity", default: 0, null: false
    t.string "description", default: "-", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "store_id"
    t.index ["item_id"], name: "index_loss_items_on_item_id"
    t.index ["loss_id"], name: "index_loss_items_on_loss_id"
    t.index ["store_id"], name: "index_loss_items_on_store_id"
  end

  create_table "losses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.integer "total_item", null: false
    t.boolean "from_retur", default: false
    t.bigint "ref_id"
    t.string "invoice", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_losses_on_store_id"
    t.index ["user_id"], name: "index_losses_on_user_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "id_card"
    t.string "card_number", null: false
    t.string "phone", null: false
    t.integer "sex"
    t.string "address"
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "point"
    t.index ["store_id"], name: "index_members_on_store_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "not_popular_items", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "item_id", null: false
    t.bigint "item_cat_id", null: false
    t.bigint "department_id", null: false
    t.integer "n_sell", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_id"
    t.index ["department_id"], name: "index_not_popular_items_on_department_id"
    t.index ["item_cat_id"], name: "index_not_popular_items_on_item_cat_id"
    t.index ["item_id"], name: "index_not_popular_items_on_item_id"
    t.index ["store_id"], name: "index_not_popular_items_on_store_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "date_created", precision: nil, null: false
    t.integer "read", default: 0, null: false
    t.string "link", null: false
    t.string "message", null: false
    t.integer "m_type", default: 1, null: false
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["from_user_id"], name: "index_notifications_on_from_user_id"
    t.index ["to_user_id"], name: "index_notifications_on_to_user_id"
  end

  create_table "opnames", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.string "file_name", null: false
    t.index ["store_id"], name: "index_opnames_on_store_id"
    t.index ["user_id"], name: "index_opnames_on_user_id"
  end

  create_table "order_invs", force: :cascade do |t|
    t.string "invoice", null: false
    t.bigint "nominal", null: false
    t.bigint "order_id", null: false
    t.datetime "date_paid", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["order_id"], name: "index_order_invs_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "receive"
    t.bigint "quantity", null: false
    t.bigint "price", null: false
    t.bigint "item_id", null: false
    t.bigint "order_id", null: false
    t.string "description", default: "-"
    t.integer "new_receive", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "discount_1", default: 0
    t.integer "discount_2", default: 0
    t.float "ppn", default: 0.0
    t.bigint "grand_total", default: 0
    t.bigint "total", default: 0, null: false
    t.float "last_buy", default: 0.0, null: false
    t.float "last_sell", default: 0.0, null: false
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "invoice", null: false
    t.datetime "date_created", precision: nil, null: false
    t.datetime "date_receive", precision: nil
    t.bigint "supplier_id", null: false
    t.bigint "store_id", null: false
    t.integer "total_items", null: false
    t.bigint "total", null: false
    t.datetime "date_paid_off", precision: nil
    t.boolean "editable", default: true, null: false
    t.bigint "old_total", default: 0, null: false
    t.datetime "date_change", precision: nil
    t.bigint "user_id", null: false
    t.bigint "received_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "salesman", default: "-"
    t.string "no_faktur", default: "-"
    t.integer "discount", default: 0
    t.float "discount_percentage", default: 0.0
    t.boolean "from_retur", default: false
    t.bigint "grand_total", default: 0
    t.bigint "tax", default: 0
    t.index ["store_id"], name: "index_orders_on_store_id"
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "outcomes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.integer "outcome_type", default: 4, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_outcomes_on_store_id"
    t.index ["user_id"], name: "index_outcomes_on_user_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "points", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "transaction_id"
    t.integer "point", null: false
    t.integer "point_type", null: false
    t.bigint "exchange_point_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "voucher_id"
    t.index ["exchange_point_id"], name: "index_points_on_exchange_point_id"
    t.index ["member_id"], name: "index_points_on_member_id"
    t.index ["transaction_id"], name: "index_points_on_transaction_id"
    t.index ["voucher_id"], name: "index_points_on_voucher_id"
  end

  create_table "popular_items", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "item_id", null: false
    t.bigint "item_cat_id", null: false
    t.bigint "department_id", null: false
    t.integer "n_sell", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_id"
    t.index ["department_id"], name: "index_popular_items_on_department_id"
    t.index ["item_cat_id"], name: "index_popular_items_on_item_cat_id"
    t.index ["item_id"], name: "index_popular_items_on_item_id"
    t.index ["store_id"], name: "index_popular_items_on_store_id"
  end

  create_table "predict_categories", force: :cascade do |t|
    t.bigint "buy_id", null: false
    t.bigint "usually_id", null: false
    t.float "percentage", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["buy_id"], name: "index_predict_categories_on_buy_id"
    t.index ["usually_id"], name: "index_predict_categories_on_usually_id"
  end

  create_table "predict_items", force: :cascade do |t|
    t.bigint "buy_id", null: false
    t.bigint "usually_id", null: false
    t.float "percentage", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["buy_id"], name: "index_predict_items_on_buy_id"
    t.index ["usually_id"], name: "index_predict_items_on_usually_id"
  end

  create_table "prints", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "store_id", null: false
    t.bigint "grocer_item_id"
    t.bigint "promotion_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["grocer_item_id"], name: "index_prints_on_grocer_item_id"
    t.index ["item_id"], name: "index_prints_on_item_id"
    t.index ["promotion_id"], name: "index_prints_on_promotion_id"
    t.index ["store_id"], name: "index_prints_on_store_id"
  end

  create_table "profit_losses", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.integer "finance_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_profit_losses_on_store_id"
    t.index ["user_id"], name: "index_profit_losses_on_user_id"
  end

  create_table "promotions", force: :cascade do |t|
    t.bigint "buy_item_id", null: false
    t.integer "buy_quantity", null: false
    t.bigint "free_item_id", null: false
    t.integer "free_quantity", null: false
    t.datetime "start_promo", precision: nil, null: false
    t.datetime "end_promo", precision: nil, null: false
    t.bigint "user_id", null: false
    t.string "promo_code", null: false
    t.integer "hit", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["buy_item_id"], name: "index_promotions_on_buy_item_id"
    t.index ["free_item_id"], name: "index_promotions_on_free_item_id"
    t.index ["user_id"], name: "index_promotions_on_user_id"
  end

  create_table "receivables", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "nominal", null: false
    t.bigint "deficiency", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.string "ref_id"
    t.integer "finance_type", null: false
    t.integer "to_user", default: 1, null: false
    t.datetime "due_date", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "n_term", default: 1, null: false
    t.float "nominal_term", default: 0.0, null: false
    t.index ["store_id"], name: "index_receivables_on_store_id"
    t.index ["user_id"], name: "index_receivables_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "cash", default: 0, null: false
    t.bigint "stock_value", default: 0, null: false
    t.bigint "receivable", default: 0, null: false
    t.bigint "asset", default: 0, null: false
    t.bigint "capital", default: 0, null: false
    t.bigint "debt", default: 0, null: false
    t.bigint "outcome", default: 0, null: false
    t.bigint "sales", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_reports_on_store_id"
  end

  create_table "retur_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "retur_id", null: false
    t.integer "quantity", null: false
    t.string "description", null: false
    t.integer "feedback", default: 0
    t.integer "accept_item", default: 0
    t.bigint "nominal", default: 0, null: false
    t.bigint "ref_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_retur_items_on_item_id"
    t.index ["retur_id"], name: "index_retur_items_on_retur_id"
  end

  create_table "returs", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "total_items", null: false
    t.bigint "store_id", null: false
    t.bigint "supplier_id", null: false
    t.datetime "date_created", precision: nil
    t.datetime "date_picked", precision: nil
    t.datetime "date_approve", precision: nil
    t.datetime "status", precision: nil
    t.bigint "user_id", null: false
    t.bigint "picked_by"
    t.bigint "approved_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "date_confirm", precision: nil
    t.bigint "confirmed_by"
    t.index ["store_id"], name: "index_returs_on_store_id"
    t.index ["supplier_id"], name: "index_returs_on_supplier_id"
    t.index ["user_id"], name: "index_returs_on_user_id"
  end

  create_table "send_back_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "send_back_id", null: false
    t.integer "quantity", null: false
    t.integer "receive", null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_send_back_items_on_item_id"
    t.index ["send_back_id"], name: "index_send_back_items_on_send_back_id"
  end

  create_table "send_backs", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "total_items", null: false
    t.bigint "store_id", null: false
    t.datetime "date_receive", precision: nil
    t.bigint "user_id", null: false
    t.bigint "received_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_send_backs_on_store_id"
    t.index ["user_id"], name: "index_send_backs_on_user_id"
  end

  create_table "stock_recaps", force: :cascade do |t|
    t.datetime "date", precision: nil, null: false
    t.string "filename", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "stock_values", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", precision: nil, null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_stock_values_on_store_id"
    t.index ["user_id"], name: "index_stock_values_on_user_id"
  end

  create_table "store_balances", force: :cascade do |t|
    t.bigint "cash", null: false
    t.bigint "receivable", null: false
    t.bigint "stock_value", null: false
    t.bigint "asset_value", null: false
    t.bigint "equity", null: false
    t.bigint "debt", null: false
    t.bigint "transaction_value", null: false
    t.bigint "outcome", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "filename"
    t.bigint "bank", default: 0, null: false
    t.index ["store_id"], name: "index_store_balances_on_store_id"
  end

  create_table "store_data", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.float "debt", default: 0.0, null: false
    t.float "receivable", default: 0.0, null: false
    t.float "tax", default: 0.0, null: false
    t.float "transaction_total", default: 0.0, null: false
    t.float "transaction_hpp", default: 0.0, null: false
    t.float "transaction_profit", default: 0.0, null: false
    t.float "transaction_tax", default: 0.0, null: false
    t.float "income", default: 0.0, null: false
    t.float "outcome", default: 0.0, null: false
    t.datetime "date", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_store_data_on_store_id"
  end

  create_table "store_items", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "item_id", null: false
    t.float "stock", default: 0.0, null: false
    t.integer "min_stock", default: 0, null: false
    t.float "buy", default: 0.0, null: false
    t.bigint "sell", default: 0, null: false
    t.float "head_buy", default: 0.0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "limit", default: 5
    t.bigint "ideal_stock", default: 10
    t.bigint "edited_by"
    t.index ["item_id"], name: "index_store_items_on_item_id"
    t.index ["store_id"], name: "index_store_items_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name", default: "DEFAULT STORE NAME", null: false
    t.string "address", default: "DEFAULT STORE ADDRESS", null: false
    t.string "phone", default: "1234567", null: false
    t.integer "store_type", default: 1, null: false
    t.bigint "cash", default: 100000000, null: false
    t.bigint "equity", default: 100000000, null: false
    t.bigint "debt", default: 0, null: false
    t.bigint "receivable", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "grand_total_before", default: 0
    t.bigint "modals_before", default: 0
    t.bigint "bank", default: 0, null: false
    t.bigint "grand_total_card_before", default: 0, null: false
    t.boolean "online_store", default: false
    t.bigint "edited_by"
  end

  create_table "supplier_items", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_supplier_items_on_item_id"
    t.index ["supplier_id"], name: "index_supplier_items_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", default: "DEFAULT NAME SUPPLIER", null: false
    t.string "address", default: "DEFAULT ADDRESS SUPPLIER", null: false
    t.string "phone", default: "123456789", null: false
    t.integer "supplier_type", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "tax", default: 0
    t.boolean "local", default: false
  end

  create_table "tests", force: :cascade do |t|
    t.string "name"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["store_id"], name: "index_tests_on_store_id"
  end

  create_table "transaction_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "transaction_id", null: false
    t.bigint "price", null: false
    t.bigint "discount", default: 0
    t.float "quantity", null: false
    t.datetime "date_created", precision: nil
    t.integer "retur"
    t.integer "replace"
    t.string "reason"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "ppn", default: 0.0, null: false
    t.bigint "supplier_id"
    t.bigint "store_id"
    t.float "profit", default: 0.0, null: false
    t.float "total", default: 0.0, null: false
    t.index ["item_id"], name: "index_transaction_items_on_item_id"
    t.index ["store_id"], name: "index_transaction_items_on_store_id"
    t.index ["supplier_id"], name: "index_transaction_items_on_supplier_id"
    t.index ["transaction_id"], name: "index_transaction_items_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.bigint "user_id", null: false
    t.bigint "total", null: false
    t.bigint "discount", default: 0
    t.bigint "grand_total", null: false
    t.integer "items", null: false
    t.integer "payment_type", default: 1
    t.integer "bank", default: 0
    t.bigint "edc_inv", default: 0
    t.datetime "date_created", precision: nil, null: false
    t.bigint "hpp_total", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "card_number"
    t.bigint "member_card"
    t.bigint "store_id", default: 1, null: false
    t.bigint "sub_from_complain", default: 0, null: false
    t.boolean "from_complain", default: false, null: false
    t.bigint "complain_id"
    t.bigint "point", default: 0, null: false
    t.bigint "voucher_id"
    t.bigint "voucher"
    t.boolean "has_coin", default: false, null: false
    t.bigint "tax", default: 0
    t.float "pembulatan", default: 0.0, null: false
    t.float "grand_total_coin", default: 0.0, null: false
    t.float "hpp_total_coin", default: 0.0, null: false
    t.float "profit_coin", default: 0.0, null: false
    t.bigint "quantity_coin", default: 0, null: false
    t.float "tax_coin", default: 0.0, null: false
    t.index ["store_id"], name: "index_transactions_on_store_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.index ["voucher_id"], name: "index_transactions_on_voucher_id"
  end

  create_table "transfer_items", force: :cascade do |t|
    t.bigint "transfer_id", null: false
    t.bigint "item_id", null: false
    t.integer "request_quantity", default: 1, null: false
    t.integer "sent_quantity", default: 0
    t.integer "receive_quantity", default: 0
    t.string "description", default: ""
    t.datetime "date_created", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_transfer_items_on_item_id"
    t.index ["transfer_id"], name: "index_transfer_items_on_transfer_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.string "invoice", null: false
    t.datetime "date_created", precision: nil, null: false
    t.datetime "date_approve", precision: nil
    t.datetime "date_picked", precision: nil
    t.datetime "date_confirm", precision: nil
    t.datetime "status", precision: nil
    t.integer "total_items"
    t.bigint "from_store_id", null: false
    t.bigint "to_store_id", null: false
    t.string "description", default: "-", null: false
    t.bigint "user_id", null: false
    t.bigint "approved_by"
    t.bigint "picked_by"
    t.bigint "confirmed_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["from_store_id"], name: "index_transfers_on_from_store_id"
    t.index ["to_store_id"], name: "index_transfers_on_to_store_id"
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "user_devices", force: :cascade do |t|
    t.string "device", null: false
    t.bigint "user_id", null: false
    t.string "ip", null: false
    t.string "action", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_user_devices_on_user_id"
  end

  create_table "user_methods", force: :cascade do |t|
    t.string "user_level", null: false
    t.bigint "controller_method_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["controller_method_id"], name: "index_user_methods_on_controller_method_id"
  end

  create_table "user_salaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "nominal", default: 0, null: false
    t.integer "checking", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "bonus", default: 0, null: false
    t.bigint "pay_receivable", default: 0, null: false
    t.bigint "pay_kasbon", default: 0, null: false
    t.string "tag", default: "", null: false
    t.bigint "jp", default: 0, null: false
    t.bigint "jht", default: 0, null: false
    t.index ["user_id"], name: "index_user_salaries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "level", default: 0, null: false
    t.string "phone", default: "62123456789", null: false
    t.string "address", default: "DEFAULT ADDRESS", null: false
    t.integer "sex", default: 0, null: false
    t.bigint "id_card", default: 123456789123456, null: false
    t.bigint "salary", default: 0, null: false
    t.string "image"
    t.integer "fingerprint"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "encrypted_password", limit: 128
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.bigint "store_id", null: false
    t.boolean "active", default: true, null: false
    t.string "temp_password"
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["store_id"], name: "index_users_on_store_id"
  end

  create_table "vouchers", force: :cascade do |t|
    t.bigint "exchange_point_id", null: false
    t.bigint "voucher_code", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "used", precision: nil
    t.index ["exchange_point_id"], name: "index_vouchers_on_exchange_point_id"
  end

  add_foreign_key "absents", "stores"
  add_foreign_key "absents", "users"
  add_foreign_key "assets", "stores"
  add_foreign_key "assets", "users"
  add_foreign_key "capitals", "stores"
  add_foreign_key "capitals", "users"
  add_foreign_key "cash_flows", "stores"
  add_foreign_key "cash_flows", "users"
  add_foreign_key "cashes", "stores"
  add_foreign_key "cashes", "users"
  add_foreign_key "complain_items", "complains"
  add_foreign_key "complain_items", "items"
  add_foreign_key "complains", "stores"
  add_foreign_key "complains", "users"
  add_foreign_key "controller_methods", "controllers"
  add_foreign_key "debts", "stores"
  add_foreign_key "debts", "suppliers"
  add_foreign_key "debts", "users"
  add_foreign_key "discounts", "items"
  add_foreign_key "finances", "stores"
  add_foreign_key "finances", "users"
  add_foreign_key "grocer_items", "items"
  add_foreign_key "incomes", "stores"
  add_foreign_key "incomes", "users"
  add_foreign_key "invoice_transactions", "stores"
  add_foreign_key "invoice_transactions", "users"
  add_foreign_key "item_cats", "departments"
  add_foreign_key "item_prices", "items"
  add_foreign_key "items", "item_cats"
  add_foreign_key "kasbons", "users"
  add_foreign_key "loss_items", "items"
  add_foreign_key "loss_items", "losses"
  add_foreign_key "loss_items", "stores"
  add_foreign_key "losses", "stores"
  add_foreign_key "losses", "users"
  add_foreign_key "members", "stores"
  add_foreign_key "members", "users"
  add_foreign_key "not_popular_items", "departments"
  add_foreign_key "not_popular_items", "item_cats"
  add_foreign_key "not_popular_items", "items"
  add_foreign_key "not_popular_items", "stores"
  add_foreign_key "notifications", "users", column: "from_user_id"
  add_foreign_key "notifications", "users", column: "to_user_id"
  add_foreign_key "opnames", "stores"
  add_foreign_key "opnames", "users"
  add_foreign_key "order_invs", "orders"
  add_foreign_key "order_items", "items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "stores"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "orders", "users"
  add_foreign_key "outcomes", "stores"
  add_foreign_key "outcomes", "users"
  add_foreign_key "points", "exchange_points"
  add_foreign_key "points", "members"
  add_foreign_key "points", "transactions"
  add_foreign_key "points", "vouchers"
  add_foreign_key "popular_items", "departments"
  add_foreign_key "popular_items", "item_cats"
  add_foreign_key "popular_items", "items"
  add_foreign_key "popular_items", "stores"
  add_foreign_key "predict_categories", "item_cats", column: "buy_id"
  add_foreign_key "predict_categories", "item_cats", column: "usually_id"
  add_foreign_key "predict_items", "items", column: "buy_id"
  add_foreign_key "predict_items", "items", column: "usually_id"
  add_foreign_key "prints", "grocer_items"
  add_foreign_key "prints", "items"
  add_foreign_key "prints", "promotions"
  add_foreign_key "prints", "stores"
  add_foreign_key "profit_losses", "stores"
  add_foreign_key "profit_losses", "users"
  add_foreign_key "promotions", "items", column: "buy_item_id"
  add_foreign_key "promotions", "items", column: "free_item_id"
  add_foreign_key "promotions", "users"
  add_foreign_key "receivables", "stores"
  add_foreign_key "receivables", "users"
  add_foreign_key "reports", "stores"
  add_foreign_key "retur_items", "items"
  add_foreign_key "retur_items", "returs"
  add_foreign_key "returs", "stores"
  add_foreign_key "returs", "suppliers"
  add_foreign_key "returs", "users"
  add_foreign_key "send_back_items", "items"
  add_foreign_key "send_back_items", "send_backs"
  add_foreign_key "send_backs", "stores"
  add_foreign_key "send_backs", "users"
  add_foreign_key "stock_values", "stores"
  add_foreign_key "stock_values", "users"
  add_foreign_key "store_balances", "stores"
  add_foreign_key "store_data", "stores"
  add_foreign_key "store_items", "items"
  add_foreign_key "store_items", "stores"
  add_foreign_key "supplier_items", "items"
  add_foreign_key "supplier_items", "suppliers"
  add_foreign_key "tests", "stores"
  add_foreign_key "transaction_items", "items"
  add_foreign_key "transaction_items", "stores"
  add_foreign_key "transaction_items", "suppliers"
  add_foreign_key "transaction_items", "transactions"
  add_foreign_key "transactions", "stores"
  add_foreign_key "transactions", "users"
  add_foreign_key "transactions", "vouchers"
  add_foreign_key "transfer_items", "items"
  add_foreign_key "transfer_items", "transfers"
  add_foreign_key "transfers", "stores", column: "from_store_id"
  add_foreign_key "transfers", "stores", column: "to_store_id"
  add_foreign_key "transfers", "users"
  add_foreign_key "user_devices", "users"
  add_foreign_key "user_methods", "controller_methods"
  add_foreign_key "user_salaries", "users"
  add_foreign_key "vouchers", "exchange_points"
end
