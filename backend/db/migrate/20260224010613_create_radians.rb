class CreateRadians < ActiveRecord::Migration[8.1]
  def change
    create_table :radians do |t|
      t.references :circle, null: false, foreign_key: true
      t.text :content
      t.float :position_angle
      t.boolean :is_archived

      t.timestamps
    end
  end
end
