class OperatingSystem < ActiveRecord::Base
  
  acts_as_paranoid
  
  has_many :nodes
  has_many :nodes_as_preferred_os,
           :class_name => 'Node',
           :foreign_key => 'preferred_operating_system_id'
  has_many :operating_system_notes, :dependent => :destroy
  
  validates_presence_of :name

  def self.default_search_attribute
    'name'
  end
 
end
