# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_23_081123) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "check_in"
    t.datetime "check_out"
    t.datetime "overtime_in"
    t.datetime "overtime_out"
    t.string "work_hour", default: "0:0:0"
    t.string "overtime_hour", default: "0:0:0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.integer "finance_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_assets_on_store_id"
    t.index ["user_id"], name: "index_assets_on_user_id"
  end

  create_table "capitals", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_capitals_on_store_id"
    t.index ["user_id"], name: "index_capitals_on_user_id"
  end

  create_table "cash_flows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.float "nominal", null: false
    t.integer "finance_type", default: 1, null: false
    t.datetime "date_created"
    t.string "description"
    t.bigint "ref_id"
    t.string "invoice", default: "-", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_cash_flows_on_store_id"
    t.index ["user_id"], name: "index_cash_flows_on_user_id"
  end

  create_table "cashes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_cashes_on_store_id"
    t.index ["user_id"], name: "index_cashes_on_user_id"
  end

  create_table "complain_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "complain_id", null: false
    t.integer "quantity", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["complain_id"], name: "index_complain_items_on_complain_id"
    t.index ["item_id"], name: "index_complain_items_on_item_id"
  end

  create_table "complains", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "total_items", null: false
    t.bigint "store_id", null: false
    t.bigint "member_id"
    t.datetime "date_created"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "transaction_id", null: false
    t.index ["member_id"], name: "index_complains_on_member_id"
    t.index ["store_id"], name: "index_complains_on_store_id"
    t.index ["transaction_id"], name: "index_complains_on_transaction_id"
    t.index ["user_id"], name: "index_complains_on_user_id"
  end

  create_table "controller_methods", force: :cascade do |t|
    t.bigint "controller_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_id"], name: "index_controller_methods_on_controller_id"
  end

  create_table "controllers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "debts", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.float "deficiency", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.integer "ref_id"
    t.integer "finance_type", null: false
    t.datetime "due_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_debts_on_store_id"
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", default: "DEFAULT (NO DEPARTMENT)", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "finances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.float "nominal", null: false
    t.integer "finance_type", default: 1, null: false
    t.datetime "date_created"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_finances_on_store_id"
    t.index ["user_id"], name: "index_finances_on_user_id"
  end

  create_table "grocer_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.integer "min", null: false
    t.integer "max", null: false
    t.float "price", null: false
    t.float "discount", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_grocer_items_on_item_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_incomes_on_store_id"
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "invoice_transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "transaction_type", default: 1, null: false
    t.string "transaction_invoice", null: false
    t.integer "nominal", default: 0, null: false
    t.datetime "date_created"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_invoice_transactions_on_user_id"
  end

  create_table "item_cats", force: :cascade do |t|
    t.string "name", default: "DEFAULT", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id"
    t.index ["department_id"], name: "index_item_cats_on_department_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "code", default: "DEFAULT_CODE", null: false
    t.string "name", default: "DEFAULT_NAME", null: false
    t.integer "stock", default: 0, null: false
    t.integer "buy", default: 1, null: false
    t.integer "sell", default: 1, null: false
    t.bigint "item_cat_id", null: false
    t.string "brand", null: false
    t.float "wholesale", default: 0.0, null: false
    t.float "box", default: 0.0, null: false
    t.string "image"
    t.float "buy_grocer", default: 0.0
    t.float "discount", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_cat_id"], name: "index_items_on_item_cat_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_members_on_store_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "date_created", null: false
    t.integer "read", default: 0, null: false
    t.string "link", null: false
    t.string "message", null: false
    t.integer "m_type", default: 1, null: false
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_notifications_on_from_user_id"
    t.index ["to_user_id"], name: "index_notifications_on_to_user_id"
  end

  create_table "order_invs", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "nominal", null: false
    t.bigint "order_id", null: false
    t.datetime "date_paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_invs_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "receive"
    t.integer "quantity", null: false
    t.integer "price", null: false
    t.bigint "item_id", null: false
    t.bigint "order_id", null: false
    t.string "description", default: "-"
    t.integer "new_receive", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "invoice", null: false
    t.datetime "date_created", null: false
    t.datetime "date_receive"
    t.bigint "supplier_id", null: false
    t.bigint "store_id", null: false
    t.integer "total_items", null: false
    t.integer "total", null: false
    t.datetime "date_paid_off"
    t.boolean "editable", default: true, null: false
    t.bigint "old_total", default: 0, null: false
    t.datetime "date_change"
    t.bigint "user_id", null: false
    t.bigint "received_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_orders_on_store_id"
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "outcomes", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.integer "outcome_type", default: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_outcomes_on_store_id"
    t.index ["user_id"], name: "index_outcomes_on_user_id"
  end

  create_table "profit_losses", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.integer "finance_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_profit_losses_on_store_id"
    t.index ["user_id"], name: "index_profit_losses_on_user_id"
  end

  create_table "receivables", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.float "deficiency", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.string "ref_id"
    t.integer "finance_type", null: false
    t.integer "to_user", default: 1, null: false
    t.datetime "due_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_receivables_on_store_id"
    t.index ["user_id"], name: "index_receivables_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.float "cash", default: 0.0, null: false
    t.float "stock_value", default: 0.0, null: false
    t.float "receivable", default: 0.0, null: false
    t.float "asset", default: 0.0, null: false
    t.float "capital", default: 0.0, null: false
    t.float "debt", default: 0.0, null: false
    t.float "outcome", default: 0.0, null: false
    t.float "sales", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_reports_on_store_id"
  end

  create_table "retur_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "retur_id", null: false
    t.integer "quantity", null: false
    t.string "description", null: false
    t.integer "feedback", default: 0
    t.integer "accept_item", default: 0
    t.float "nominal", default: 0.0, null: false
    t.bigint "ref_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_retur_items_on_item_id"
    t.index ["retur_id"], name: "index_retur_items_on_retur_id"
  end

  create_table "returs", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "total_items", null: false
    t.bigint "store_id", null: false
    t.bigint "supplier_id", null: false
    t.datetime "date_created"
    t.datetime "date_picked"
    t.datetime "date_approve"
    t.datetime "status"
    t.bigint "user_id", null: false
    t.bigint "picked_by"
    t.bigint "approved_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_returs_on_store_id"
    t.index ["supplier_id"], name: "index_returs_on_supplier_id"
    t.index ["user_id"], name: "index_returs_on_user_id"
  end

  create_table "stock_values", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.float "nominal", null: false
    t.datetime "date_created", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_stock_values_on_store_id"
    t.index ["user_id"], name: "index_stock_values_on_user_id"
  end

  create_table "store_items", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "item_id", null: false
    t.integer "stock", default: 0, null: false
    t.integer "min_stock", default: 0, null: false
    t.float "buy", default: 0.0, null: false
    t.float "sell", default: 0.0, null: false
    t.float "head_buy", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_store_items_on_item_id"
    t.index ["store_id"], name: "index_store_items_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name", default: "DEFAULT STORE NAME", null: false
    t.string "address", default: "DEFAULT STORE ADDRESS", null: false
    t.string "phone", default: "1234567", null: false
    t.integer "store_type", default: 1, null: false
    t.float "cash", default: 100000000.0, null: false
    t.float "equity", default: 100000000.0, null: false
    t.float "debt", default: 0.0, null: false
    t.float "receivable", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "supplier_items", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_supplier_items_on_item_id"
    t.index ["supplier_id"], name: "index_supplier_items_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", default: "DEFAULT NAME SUPPLIER", null: false
    t.string "address", default: "DEFAULT ADDRESS SUPPLIER", null: false
    t.string "phone", default: "123456789", null: false
    t.integer "supplier_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "transaction_id", null: false
    t.integer "price", null: false
    t.integer "discount", default: 0
    t.integer "quantity", null: false
    t.datetime "date_created"
    t.integer "retur"
    t.integer "replace"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_transaction_items_on_item_id"
    t.index ["transaction_id"], name: "index_transaction_items_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.bigint "user_id", null: false
    t.bigint "member_id"
    t.float "total", null: false
    t.float "discount", default: 0.0
    t.float "grand_total", null: false
    t.integer "items", null: false
    t.integer "payment_type", default: 1
    t.integer "bank", default: 0
    t.float "edc_inv", default: 0.0
    t.datetime "date_created", null: false
    t.float "hpp_total", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_transactions_on_member_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "transfer_items", force: :cascade do |t|
    t.bigint "transfer_id", null: false
    t.bigint "item_id", null: false
    t.integer "request_quantity", default: 1, null: false
    t.integer "sent_quantity", default: 0
    t.integer "receive_quantity", default: 0
    t.string "description", default: ""
    t.datetime "date_created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_transfer_items_on_item_id"
    t.index ["transfer_id"], name: "index_transfer_items_on_transfer_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.string "invoice", null: false
    t.datetime "date_created", null: false
    t.datetime "date_approve"
    t.datetime "date_picked"
    t.datetime "date_confirm"
    t.datetime "status"
    t.integer "total_items"
    t.bigint "from_store_id", null: false
    t.bigint "to_store_id", null: false
    t.string "description", default: "-", null: false
    t.bigint "user_id", null: false
    t.bigint "approved_by"
    t.bigint "picked_by"
    t.bigint "confirmed_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_store_id"], name: "index_transfers_on_from_store_id"
    t.index ["to_store_id"], name: "index_transfers_on_to_store_id"
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "user_methods", force: :cascade do |t|
    t.string "user_level", null: false
    t.bigint "controller_method_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_method_id"], name: "index_user_methods_on_controller_method_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "level", default: 0, null: false
    t.string "phone", default: "62123456789", null: false
    t.string "address", default: "DEFAULT ADDRESS", null: false
    t.integer "sex", default: 0, null: false
    t.bigint "id_card", default: 123456789123456, null: false
    t.float "salary", default: 0.0, null: false
    t.string "image"
    t.integer "fingerprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", limit: 128
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.bigint "store_id", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["store_id"], name: "index_users_on_store_id"
  end

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
  add_foreign_key "complains", "members"
  add_foreign_key "complains", "stores"
  add_foreign_key "complains", "users"
  add_foreign_key "controller_methods", "controllers"
  add_foreign_key "debts", "stores"
  add_foreign_key "debts", "users"
  add_foreign_key "finances", "stores"
  add_foreign_key "finances", "users"
  add_foreign_key "grocer_items", "items"
  add_foreign_key "incomes", "stores"
  add_foreign_key "incomes", "users"
  add_foreign_key "invoice_transactions", "users"
  add_foreign_key "item_cats", "departments"
  add_foreign_key "items", "item_cats"
  add_foreign_key "members", "stores"
  add_foreign_key "members", "users"
  add_foreign_key "notifications", "users", column: "from_user_id"
  add_foreign_key "notifications", "users", column: "to_user_id"
  add_foreign_key "order_invs", "orders"
  add_foreign_key "order_items", "items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "stores"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "orders", "users"
  add_foreign_key "outcomes", "stores"
  add_foreign_key "outcomes", "users"
  add_foreign_key "profit_losses", "stores"
  add_foreign_key "profit_losses", "users"
  add_foreign_key "receivables", "stores"
  add_foreign_key "receivables", "users"
  add_foreign_key "reports", "stores"
  add_foreign_key "retur_items", "items"
  add_foreign_key "retur_items", "returs"
  add_foreign_key "returs", "stores"
  add_foreign_key "returs", "suppliers"
  add_foreign_key "returs", "users"
  add_foreign_key "stock_values", "stores"
  add_foreign_key "stock_values", "users"
  add_foreign_key "store_items", "items"
  add_foreign_key "store_items", "stores"
  add_foreign_key "supplier_items", "items"
  add_foreign_key "supplier_items", "suppliers"
  add_foreign_key "transaction_items", "items"
  add_foreign_key "transaction_items", "transactions"
  add_foreign_key "transactions", "members"
  add_foreign_key "transactions", "users"
  add_foreign_key "transfer_items", "items"
  add_foreign_key "transfer_items", "transfers"
  add_foreign_key "transfers", "stores", column: "from_store_id"
  add_foreign_key "transfers", "stores", column: "to_store_id"
  add_foreign_key "transfers", "users"
  add_foreign_key "user_methods", "controller_methods"
end
