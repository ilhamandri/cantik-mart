class PredictCategory < ApplicationRecord
  belongs_to :buy, class_name: "ItemCat", foreign_key: "buy_id", optional: true
  belongs_to :usually, class_name: "ItemCat", foreign_key: "usually_id", optional: true
  
end