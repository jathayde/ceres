class CreateSeedSources < ActiveRecord::Migration[8.1]
  def change
    create_table :seed_sources do |t|
      t.string :name, null: false
      t.string :url
      t.text :notes

      t.timestamps
    end

    add_index :seed_sources, :name, unique: true
  end
end
