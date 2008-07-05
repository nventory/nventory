class AddRelevantModelToStatusObject < ActiveRecord::Migration
  def self.up
    # add a column to status that will use to limit what status can be applied to which models
    add_column "statuses", "relevant_model", :string
    
    # Some System Install Defaults
    s1 = Status.new
    s1.name = 'inservice'
    s1.relevant_model = 'Node'
    s1.notes = 'Hardware and OS functional, applications running'
    s1.save
    s2 = Status.new
    s2.name = 'outofservice'
    s2.relevant_model = 'Node'
    s2.notes = 'Hardware and OS functional, applications not running'
    s2.save
    s3 = Status.new
    s3.name = 'available'
    s3.relevant_model = 'Node'
    s3.notes = 'Hardware functional, no applications assigned'
    s3.save
    s4 = Status.new
    s4.name = 'broken'
    s4.relevant_model = 'Node'
    s4.notes = 'Hardware or OS not functional'
    s4.save
    s5 = Status.new
    s5.name = 'setup'
    s5.relevant_model = 'Node'
    s5.notes = 'New node, not yet configured'
    s5.save
    
  end

  def self.down
    remove_column "statuses", "relevant_model"
  end
end
