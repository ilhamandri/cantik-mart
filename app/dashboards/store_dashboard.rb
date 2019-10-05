require "administrate/base_dashboard"

class StoreDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    activities: Field::HasMany.with_options(class_name: "::PublicActivity::Activity"),
    users: Field::HasMany,
    store_items: Field::HasMany,
    retur: Field::HasMany,
    members: Field::HasMany,
    complains: Field::HasMany,
    transactions: Field::HasMany,
    store_balances: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    address: Field::String,
    phone: Field::String,
    store_type: Field::String.with_options(searchable: false),
    cash: Field::Number.with_options(decimals: 2),
    equity: Field::Number.with_options(decimals: 2),
    debt: Field::Number.with_options(decimals: 2),
    receivable: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    grand_total_before: Field::Number.with_options(decimals: 2),
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :activities,
    :users,
    :store_items,
    :retur,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :activities,
    :users,
    :store_items,
    :retur,
    :members,
    :complains,
    :transactions,
    :store_balances,
    :id,
    :name,
    :address,
    :phone,
    :store_type,
    :cash,
    :equity,
    :debt,
    :receivable,
    :created_at,
    :updated_at,
    :grand_total_before,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :activities,
    :users,
    :store_items,
    :retur,
    :members,
    :complains,
    :transactions,
    :store_balances,
    :name,
    :address,
    :phone,
    :store_type,
    :cash,
    :equity,
    :debt,
    :receivable,
    :grand_total_before,
  ].freeze

  # Overwrite this method to customize how stores are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(store)
  #   "Store ##{store.id}"
  # end
end
