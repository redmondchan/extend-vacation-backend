class Year < ApplicationRecord
  has_many :holidays
  has_many :results
end
