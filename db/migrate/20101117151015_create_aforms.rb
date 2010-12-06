class CreateAforms < ActiveRecord::Migration
  def self.up
    create_table :aforms do |t|
      t.string :title, :null => false
      t.string :stub, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :aforms
  end
end
