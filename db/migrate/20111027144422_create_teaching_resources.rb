class CreateTeachingResources < ActiveRecord::Migration
  def self.up
    create_table :teaching_resources do |t|
      t.integer :discipline_id
      t.string :title
      t.string :url
      t.text :description
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :teaching_resources
  end
end
