class Outlet < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :producer, :class_name => "Node", :foreign_key => "producer_id"
  belongs_to :consumer, :class_name => "Node", :foreign_key => "consumer_id"
  
  validates_presence_of :name, :producer_id
  
  def validate 
    if !self.consumer_id.nil? and self.consumer_id > 0
      
      # if this outlet has a consumer node, make sure said node isn't already over it's limit for this producer's service type
      
      outlet_type = self.producer.hardware_profile.outlet_type
      current_outlets_in_use_by_consumer = Outlet.find_all_by_consumer_id(self.consumer_id)
      current_outlets_in_use_by_consumer = current_outlets_in_use_by_consumer - [self]
      current_network_outlets_in_use_by_consumer = []
      current_power_outlets_in_use_by_consumer = []
      
      current_outlets_in_use_by_consumer.each do |outlet|
        if outlet.producer.hardware_profile.outlet_type == 'Network'
          current_network_outlets_in_use_by_consumer << outlet
        elsif outlet.producer.hardware_profile.outlet_type == 'Power'
          current_power_outlets_in_use_by_consumer << outlet
        end
      end
      
      if outlet_type == 'Network'
        errors.add(:consumer_id, "does not have any available network plugs") unless current_network_outlets_in_use_by_consumer.length < Node.find(self.consumer_id).hardware_profile.nics
      elsif outlet_type == 'Power'
        errors.add(:consumer_id, "does not have any available power plugs") unless current_power_outlets_in_use_by_consumer.length < Node.find(self.consumer_id).hardware_profile.power_supply_count
      end
      
    end
  end
  
end
