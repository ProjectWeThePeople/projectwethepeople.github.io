class CreateConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :connections do |t|
      t.references :from_user, null: false, foreign_key: true
      t.references :to_user, null: false, foreign_key: true
      t.integer :connection_type
      t.integer :status

      t.timestamps
    end
  end
end
