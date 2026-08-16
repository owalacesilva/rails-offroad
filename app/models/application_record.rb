class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # As chaves primárias são UUID, mas o MySQL não tem o gen_random_uuid() que o
  # Postgres executava como default da coluna: sem RETURNING no INSERT, o Rails
  # não teria como ler de volta um id gerado pelo banco e `record.id` viria nulo.
  # Por isso o valor é atribuído aqui, antes do INSERT.
  before_create :assign_uuid_primary_key

  private
    def assign_uuid_primary_key
      key = self.class.primary_key
      # technical_spec_values tem chave composta (ad_id, attribute_id): não é UUID
      # próprio, vem das duas pontas do EAV.
      return unless key.is_a?(String)

      self[key] ||= SecureRandom.uuid
    end
end
