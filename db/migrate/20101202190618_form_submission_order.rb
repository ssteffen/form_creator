class FormSubmissionOrder < ActiveRecord::Migration
  def self.up
    add_column :aforms, :field_order, :text
  end

  def self.down
    remove_column :aforms, :field_order
  end
end
