class Customer < ActiveRecord::Base
  
  acts_as_paranoid
  
  has_many :programs
  
  validates_presence_of :name
  
  def self.default_search_attribute
    'name'
  end
 
  def environments  
    elist = []
    self.programs.each do |p|
      p.environments.each do |e|
        elist << e
      end
    end
    elist.uniq
  end
  
  def before_destroy
    raise "A customer can not be destroyed that has programs assigned to it." if self.programs.count > 0
  end
  
end
