class CreateSeedPurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :seed_purchases do |t|
      t.references :plant, null: false, foreign_key: true
      t.references :seed_source, null: false, foreign_key: true
      t.integer :year_purchased, null: false
      t.string :lot_number
      t.decimal :germination_rate, precision: 5, scale: 4
      t.decimal :weight_oz
      t.integer :seed_count
      t.integer :packet_count, default: 1
      t.integer :cost_cents
      t.boolean :used_up, default: false, null: false
      t.date :used_up_at
      t.string :reorder_url
      t.text :notes

      t.timestamps
    end
  end
end
