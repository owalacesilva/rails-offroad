require "rails_helper"

# As chaves primárias do projeto são bigint sequenciais. Antes eram UUID em
# VARCHAR(36), geradas em um before_create do ApplicationRecord — este spec é o
# que impede a volta silenciosa daquele desenho numa tabela nova.
RSpec.describe "Esquema", type: :model do
  # active_storage_* são do framework e já nascem bigint; ficam de fora só para
  # o spec falar das tabelas do projeto.
  def project_tables
    ActiveRecord::Base.connection.tables.grep_v(/\Aactive_storage_|\Aar_internal|\Aschema_migrations\z/)
  end

  it "usa bigint em toda chave primária" do
    types = project_tables.filter_map do |table|
      key = ActiveRecord::Base.connection.primary_key(table)
      # technical_spec_values tem chave composta: não há coluna única a checar.
      next if key.blank? || key.is_a?(Array)

      [ table, ActiveRecord::Base.connection.columns(table).find { |c| c.name == key }.sql_type ]
    end

    expect(types.map(&:last).uniq).to eq([ "bigint" ])
  end

  it "não deixou nenhuma coluna de id como VARCHAR(36)" do
    leftovers = project_tables.flat_map do |table|
      ActiveRecord::Base.connection.columns(table)
                        .select { |column| column.name.end_with?("_id") && column.sql_type.start_with?("varchar") }
                        .map { |column| "#{table}.#{column.name}" }
    end

    expect(leftovers).to be_empty
  end

  # int com quatro bytes — o "int(11)" do dicionário de dados. O MySQL 8.4 já
  # não imprime a largura, que foi depreciada, mas o tipo é o mesmo.
  it "guarda dinheiro em int" do
    money = {
      "ads" => "price_cents",
      "proposals" => "offered_value_cents"
    }

    types = money.map do |table, column|
      ActiveRecord::Base.connection.columns(table).find { |c| c.name == column }.sql_type
    end

    expect(types).to all(eq("int"))
  end

  it "não guarda mais dinheiro em decimal" do
    decimals = %w[ads proposals].flat_map do |table|
      ActiveRecord::Base.connection.columns(table)
                        .select { |column| column.sql_type.start_with?("decimal") }
                        .map(&:name)
    end

    expect(decimals).to be_empty
  end
end
