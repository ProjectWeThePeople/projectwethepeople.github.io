class CreateCircles < ActiveRecord::Migration[7.0]
  def change
    create_table :circles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.boolean :is_public, default: false
      t.string :color_theme, default: '#4F46E5'
      t.integer :version, default: 1
      
      t.timestamps
    end
    
    add_index :circles, [:user_id, :created_at]
    add_index :circles, :is_public
    add_index :circles, :updated_at
  end
end