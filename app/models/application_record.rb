class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # As chaves primárias são UUID, mas o MySQL não tem o gen_random_uuid() que o
  # Postgres executava como default da coluna: sem RETURNING no INSERT, o Rails
  # não teria como ler de volta um id gerado pelo banco e `record.id` viria nulo.
  # Por isso o valor é atribuído aqui, antes do INSERT.
  before_create :assign_uuid_primary_key

  # O formulário trabalha em reais; a coluna é DECIMAL com ponto. Vive aqui
  # porque preço de anúncio e valor de proposta precisam do mesmo tratamento.
  #
  # Havendo vírgula, ela é o separador decimal e o ponto só pode ser separador
  # de milhar: "45.000,50" vira "45000.50". Sem vírgula o ponto é preservado,
  # porque aí é ele o decimal ("45000.50", teclado en-US). Quem converte de
  # fato continua sendo o cast do Rails.
  def self.normalize_decimal(value)
    return value unless value.is_a?(String)

    text = value.strip
    text.include?(",") ? text.delete(".").tr(",", ".") : text
  end

  private
    def assign_uuid_primary_key
      key = self.class.primary_key
      # technical_spec_values tem chave composta (ad_id, attribute_id): não é UUID
      # próprio, vem das duas pontas do EAV.
      return unless key.is_a?(String)

      self[key] ||= SecureRandom.uuid
    end
end
