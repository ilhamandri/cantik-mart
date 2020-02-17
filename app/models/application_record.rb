class ApplicationRecord < ActiveRecord::Base
  include PublicActivity::Model
  self.abstract_class = true
end
