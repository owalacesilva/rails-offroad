# This migration comes from active_storage (originally 20170806125915)
#
# Alterada em um ponto: `record_id` é VARCHAR(36), não bigint.
#
# As chaves primárias deste projeto são UUID em VARCHAR(36) (ver
# app/models/application_record.rb), e `active_storage_attachments.record_id`
# aponta para elas — com o bigint que o Rails gera por padrão, anexar a um
# AdImage falharia na hora de gravar o id. As tabelas do Active Storage seguem
# com id bigint de propósito: quem os gera é o próprio framework, cujos modelos
# herdam de ActiveRecord::Base e não passam pelo nosso before_create.
class CreateActiveStorageTables < ActiveRecord::Migration[7.0]
  # Igual ao limite das nossas chaves primárias.
  RECORD_ID_LIMIT = 36

  def change
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :active_storage_blobs, id: primary_key_type do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments, id: primary_key_type do |t|
      t.string     :name,     null: false
      # t.references :record, polymorphic: true daria a record_id o mesmo tipo
      # de blob_id. Aqui os dois divergem: o blob é do Rails (bigint) e o
      # registro anexado é nosso (UUID), então as colunas são escritas à mão.
      t.string     :record_type, null: false
      t.string     :record_id,   null: false, limit: RECORD_ID_LIMIT
      t.references :blob,        null: false, type: foreign_key_type

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records, id: primary_key_type do |t|
      t.belongs_to :blob, null: false, index: false, type: foreign_key_type
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [ primary_key_type, foreign_key_type ]
    end
end
