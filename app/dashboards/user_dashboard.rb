require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    activities: Field::HasMany.with_options(class_name: "::PublicActivity::Activity"),
    store: Field::BelongsTo,
    transactions: Field::HasMany,
    absents: Field::HasMany,
    methods: Field::HasMany,
    members: Field::HasMany,
    notifications: Field::HasMany,
    transfers: Field::HasMany,
    invoice_transactions: Field::HasMany,
    complains: Field::HasMany,
    user_salaries: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    email: Field::String,
    level: Field::String.with_options(searchable: false),
    phone: Field::String,
    address: Field::String,
    sex: Field::String.with_options(searchable: false),
    id_card: Field::Number,
    salary: Field::Number.with_options(decimals: 2),
    image: Field::String,
    fingerprint: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    encrypted_password: Field::String,
    confirmation_token: Field::String,
    remember_token: Field::String,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :activities,
    :store,
    :transactions,
    :absents,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :activities,
    :store,
    :transactions,
    :absents,
    :methods,
    :members,
    :notifications,
    :transfers,
    :invoice_transactions,
    :complains,
    :user_salaries,
    :id,
    :name,
    :email,
    :level,
    :phone,
    :address,
    :sex,
    :id_card,
    :salary,
    :image,
    :fingerprint,
    :created_at,
    :updated_at,
    :encrypted_password,
    :confirmation_token,
    :remember_token,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :activities,
    :store,
    :transactions,
    :absents,
    :methods,
    :members,
    :notifications,
    :transfers,
    :invoice_transactions,
    :complains,
    :user_salaries,
    :name,
    :email,
    :level,
    :phone,
    :address,
    :sex,
    :id_card,
    :salary,
    :image,
    :fingerprint,
    :encrypted_password,
    :confirmation_token,
    :remember_token,
  ].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   "User ##{user.id}"
  # end
end
