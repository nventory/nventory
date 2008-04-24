class HardwareProfile < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_numericality_of :rack_size,             :only_integer => true
  validates_numericality_of :processor_count,       :only_integer => true
  validates_numericality_of :outlet_count,          :only_integer => true
  validates_numericality_of :estimated_cost,        :only_integer => true
  validates_numericality_of :power_supply_count,    :only_integer => true
  validates_numericality_of :nics,                  :only_integer => true

  def self.allowed_outlet_types
    ['Power','Network']
  end
  
  # FIXME: Dry this up.
  def validate 
    if !self.rack_size.nil? and self.rack_size < 0
      errors.add(:rack_size, "can not be negative") 
    end
    
    if !self.processor_count.nil? and self.processor_count < 0
      errors.add(:processor_count, "can not be negative") 
    end 
    
    if !self.outlet_count.nil? and self.outlet_count < 0
      errors.add(:outlet_count, "can not be negative") 
    end 
    
    if !self.estimated_cost.nil? and self.estimated_cost < 0
      errors.add(:estimated_cost, "can not be negative") 
    end
    
    if !self.power_supply_count.nil? and self.power_supply_count < 0
      errors.add(:power_supply_count, "can not be negative") 
    end
    
    if !self.nics.nil? and self.nics < 0
      errors.add(:nics, "can not be negative") 
    end
  end
  
end
