class CreateCities < ActiveRecord::Migration[8.1]
  STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO
  ].freeze

  def change
    # Os 5.570 municípios brasileiros mais Fernando de Noronha, que o IBGE lista
    # junto embora seja distrito estadual de PE. Dado de referência: não pertence
    # a anunciante nenhum e é populado na inicialização (ver lib/brazilian_cities.rb).
    create_table :cities do |t|
      # Código do IBGE, sempre com 7 dígitos. É a chave natural do município e o
      # que sobrevive a uma mudança de nome — mas a chave primária segue sendo o
      # bigint sequencial, como em todas as outras tabelas.
      t.string :ibge_code, limit: 7, null: false
      t.string :name, null: false
      t.string :state, limit: 2, null: false

      t.timestamps
    end

    add_index :cities, :ibge_code, unique: true
    # Nome de município se repete pelo país (há cinco "Bom Jesus"), mas nunca
    # dentro do mesmo estado — por isso o par, e não o nome sozinho.
    add_index :cities, %i[state name], unique: true

    add_check_constraint :cities,
                         "state IN (#{STATES.map { |uf| "'#{uf}'" }.join(',')})",
                         name: "cities_state_valid"
    # A coluna tem limite 7, o que já barra código maior; a constraint cobre o
    # resto: código curto, com letra ou zerado não é código do IBGE.
    add_check_constraint :cities,
                         "ibge_code REGEXP '^[1-9][0-9]{6}$'",
                         name: "cities_ibge_code_valid"
  end
end
