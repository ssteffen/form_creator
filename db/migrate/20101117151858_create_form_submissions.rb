class CreateFormSubmissions < ActiveRecord::Migration
  def self.up
    create_table :form_submissions do |t|
      t.text :response
      t.integer :form_id, :null => true
      t.integer :a_form_id, :null => true
      t.text :field_order
      t.timestamps
    end
  end

  def self.down
    drop_table :form_submissions
  end
end
