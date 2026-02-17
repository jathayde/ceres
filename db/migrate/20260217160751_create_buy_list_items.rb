class CreateBuyListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :buy_list_items do |t|
      t.references :plant_category, null: true, foreign_key: true
      t.references :plant_subcategory, null: true, foreign_key: true
      t.references :plant, null: true, foreign_key: true
      t.references :seed_purchase, null: true, foreign_key: true
      t.integer :status, null: false, default: 0
      t.text :notes
      t.datetime :purchased_at

      t.timestamps
    end

    add_check_constraint :buy_list_items,
      "(plant_category_id IS NOT NULL AND plant_subcategory_id IS NULL AND plant_id IS NULL) OR " \
      "(plant_category_id IS NULL AND plant_subcategory_id IS NOT NULL AND plant_id IS NULL) OR " \
      "(plant_category_id IS NULL AND plant_subcategory_id IS NULL AND plant_id IS NOT NULL)",
      name: "chk_buy_list_item_exactly_one_target"
  end
end
