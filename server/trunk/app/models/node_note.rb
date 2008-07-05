class NodeNote < ActiveRecord::Base
  
  belongs_to :node
  
  validates_presence_of :node_id, :note
  
  # node.name would be cooler
  def self.default_search_attribute
    'node_id'
  end
 
end
