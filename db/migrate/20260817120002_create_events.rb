class CreateEvents < ActiveRecord::Migration[8.1]
  STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO
  ].freeze

  def change
    # Agenda do off-road: trilhas, encontros e feiras. Não pertence a nenhum
    # anunciante — é conteúdo do portal, editado por quem o mantém.
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      # Data, não datetime: a agenda mostra o dia, e uma hora em UTC só criaria
      # a chance de um evento aparecer como "amanhã" na virada do fuso.
      t.date :starts_on, null: false
      # Nulo em evento de um dia só.
      t.date :ends_on
      t.string :city, null: false
      t.string :state, limit: 2, null: false
      # Onde acontece, dentro da cidade: "Serra do Rio do Rastro", "Parque de Exposições".
      t.string :venue
      # Site ou inscrição do evento. O portal não organiza nada, só anuncia.
      t.string :url
      t.string :image_url

      t.timestamps
    end

    # A home busca "a partir de hoje, os mais próximos primeiro": é este índice.
    add_index :events, :starts_on
    add_index :events, %i[state city]

    add_check_constraint :events,
                         "state IN (#{STATES.map { |uf| "'#{uf}'" }.join(',')})",
                         name: "events_state_valid"
    # Evento que termina antes de começar é dado corrompido, não um caso de uso.
    add_check_constraint :events,
                         "ends_on IS NULL OR ends_on >= starts_on",
                         name: "events_dates_ordered"
  end
end
