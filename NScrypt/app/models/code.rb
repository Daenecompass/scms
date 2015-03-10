class Code < ActiveRecord::Base
  belongs_to :contract;
  has_many :parties;
  has_many :sc_events;
end
