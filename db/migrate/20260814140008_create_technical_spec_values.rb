# Lado "Value" do EAV: chave primária composta (ad_id, attribute_id) garante que
# um anúncio não tenha o mesmo atributo duas vezes.
class CreateTechnicalSpecValues < ActiveRecord::Migration[8.1]
  def change
    create_table :technical_spec_values, primary_key: %i[ad_id attribute_id] do |t|
      t.uuid :ad_id, null: false
      t.uuid :attribute_id, null: false
      # Sempre texto; o data_type do atributo diz como interpretar.
      t.string :value, null: false

      t.timestamps
    end

    add_foreign_key :technical_spec_values, :ads, column: :ad_id
    add_foreign_key :technical_spec_values, :attributes, column: :attribute_id

    add_index :technical_spec_values, :attribute_id
  end
end
