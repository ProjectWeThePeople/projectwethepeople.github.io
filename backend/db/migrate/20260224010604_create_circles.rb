class CreateCircles < ActiveRecord::Migration[8.1]
  def change
    create_table :circles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.boolean :is_public
      t.string :color_theme
      t.integer :version

      t.timestamps
    end
  end
end
