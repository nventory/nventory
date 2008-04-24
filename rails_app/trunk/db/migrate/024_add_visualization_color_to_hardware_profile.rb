class AddVisualizationColorToHardwareProfile < ActiveRecord::Migration
  def self.up
    add_column "hardware_profiles", "visualization_color", :string, :default => 'red'
    add_column "hardware_profile_versions", "visualization_color", :string, :default => 'red'
  end

  def self.down
    remove_column "hardware_profiles", "visualization_color"
    remove_column "hardware_profile_versions", "visualization_color"
  end
end
