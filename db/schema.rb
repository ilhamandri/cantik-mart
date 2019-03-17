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

ActiveRecord::Schema.define(version: 2019_03_14_070733) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "member_id", null: false
    t.datetime "date_created"
    t.index ["member_id"], name: "index_complains_on_member_id"
    t.index ["store_id"], name: "index_complains_on_store_id"
  end

  create_table "finances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.integer "nominal", null: false
    t.integer "finance_type", default: 1, null: false
    t.datetime "date_created"
    t.string "description"
    t.boolean "status", default: false
    t.bigint "order_id"
    t.index ["order_id"], name: "index_finances_on_order_id"
    t.index ["store_id"], name: "index_finances_on_store_id"
    t.index ["user_id"], name: "index_finances_on_user_id"
  end

  create_table "invoice_transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "transaction_type", default: 1, null: false
    t.string "transaction_invoice", null: false
    t.integer "nominal", default: 0, null: false
    t.datetime "date_created"
  end

  create_table "item_cats", force: :cascade do |t|
    t.string "name", default: "DEFAULT", null: false
  end

  create_table "items", force: :cascade do |t|
    t.string "code", default: "DEFAULT_CODE", null: false
    t.string "name", default: "DEFAULT_NAME", null: false
    t.integer "stock", default: 0, null: false
    t.integer "buy", default: 1, null: false
    t.integer "sell", default: 1, null: false
    t.bigint "item_cat_id", null: false
    t.string "brand", default: "DEFAULT BRAND", null: false
    t.index ["item_cat_id"], name: "index_items_on_item_cat_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name", null: false
    t.string "id_card"
    t.string "card_number", null: false
    t.string "phone", null: false
    t.integer "sex"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_invs", force: :cascade do |t|
    t.string "invoice", null: false
    t.integer "nominal", null: false
    t.bigint "order_id", null: false
    t.date "date_paid"
    t.index ["order_id"], name: "index_order_invs_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "receive"
    t.integer "quantity", null: false
    t.integer "price", null: false
    t.bigint "item_id", null: false
    t.bigint "order_id", null: false
    t.string "description"
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
    t.index ["store_id"], name: "index_orders_on_store_id"
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
  end

  create_table "retur_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "retur_id", null: false
    t.integer "quantity", null: false
    t.string "description", null: false
    t.integer "feedback", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "accept_item", default: 0
    t.integer "nominal", default: 0, null: false
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
    t.index ["store_id"], name: "index_returs_on_store_id"
    t.index ["supplier_id"], name: "index_returs_on_supplier_id"
  end

  create_table "store_items", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "item_id", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_stock", default: 0, null: false
    t.index ["item_id"], name: "index_store_items_on_item_id"
    t.index ["store_id"], name: "index_store_items_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name", default: "DEFAULT STORE NAME", null: false
    t.string "address", default: "DEFAULT STORE ADDRESS", null: false
    t.string "phone", default: "1234567", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store_type", default: 0
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
    t.string "pic", default: "DEFAULT NAME SUPPLIER", null: false
    t.string "address", default: "DEFAULT ADDRESS SUPPLIER", null: false
    t.string "phone", default: "123456789", null: false
    t.integer "supplier_type", default: 0
  end

  create_table "transaction_items", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "transaction_id", null: false
    t.integer "price", null: false
    t.integer "discount", default: 0
    t.integer "quantity", null: false
    t.datetime "date_created"
    t.index ["item_id"], name: "index_transaction_items_on_item_id"
    t.index ["transaction_id"], name: "index_transaction_items_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "invoice", null: false
    t.bigint "user_id", null: false
    t.bigint "member_id"
    t.integer "total", null: false
    t.integer "discount", default: 0
    t.integer "grand_total", null: false
    t.integer "items", null: false
    t.integer "payment_type", default: 1
    t.integer "bank", default: 0
    t.integer "edc_inv", default: 0
    t.datetime "date_created", null: false
    t.integer "hpp_total"
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
    t.index ["from_store_id"], name: "index_transfers_on_from_store_id"
    t.index ["to_store_id"], name: "index_transfers_on_to_store_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "level", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", limit: 128
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.string "phone", default: "8123456789", null: false
    t.string "address", default: "DEFAULT ADDRESS", null: false
    t.bigint "id_card", default: 123456789123456, null: false
    t.integer "sex", default: 0, null: false
    t.bigint "store_id"
    t.integer "salary", default: 0
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["store_id"], name: "index_users_on_store_id"
  end

  add_foreign_key "complain_items", "complains"
  add_foreign_key "complain_items", "items"
  add_foreign_key "complains", "members"
  add_foreign_key "complains", "stores"
  add_foreign_key "finances", "stores"
  add_foreign_key "finances", "users"
  add_foreign_key "items", "item_cats"
  add_foreign_key "order_invs", "orders"
  add_foreign_key "order_items", "items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "stores"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "retur_items", "items"
  add_foreign_key "retur_items", "returs"
  add_foreign_key "returs", "stores"
  add_foreign_key "returs", "suppliers"
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
  add_foreign_key "users", "stores"
end