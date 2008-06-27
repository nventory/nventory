class AddPowerSupplyCountToHardwareProfile < ActiveRecord::Migration
  def self.up
    add_column "hardware_profiles", "power_supply_count", :integer, :default => 0
    add_column "hardware_profile_versions", "power_supply_count", :integer, :default => 0
  end

  def self.down
    remove_column "hardware_profiles", "power_supply_count"
    remove_column "hardware_profile_versions", "power_supply_count"
  end
end
