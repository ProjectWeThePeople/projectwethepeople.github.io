class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.references :circle, null: false, foreign_key: true
      t.references :shared_by_user, null: false, foreign_key: true
      t.references :shared_with_user, null: false, foreign_key: true
      t.integer :permission_level

      t.timestamps
    end
  end
end
