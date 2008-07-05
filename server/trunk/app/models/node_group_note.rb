class NodeGroupNote < ActiveRecord::Base
  
  belongs_to :node_group
  
  validates_presence_of :node_group_id, :note
  
  # node_group.name would be cooler
  def self.default_search_attribute
    'node_group_id'
  end
 
end
