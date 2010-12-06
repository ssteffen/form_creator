class CreateForms < ActiveRecord::Migration
  def self.up
    create_table :forms do |t|
      t.string :title, :null => false
      t.string :stub, :null => false
      t.string :email_notification_address, :null => false
      t.text :prepend_content, :null => true
      t.text :append_content, :null => true
      t.text :fields, :null => false
      t.text :success_message, :null => false
      t.text :failure_message, :null => false
      t.text :unavailable_message, :null => false
      t.boolean :enabled
      t.boolean :email_confirmation
      t.datetime :available_at
      t.datetime :unavailable_at
      t.timestamps
    end
  end

  def self.down
    drop_table :forms
  end
end
