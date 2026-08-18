class AddModerationNoteToAds < ActiveRecord::Migration[8.1]
  def change
    # O recado do moderador para o anunciante. Preenchido ao rejeitar e também
    # ao bloquear foto suficiente para o anúncio cair abaixo do mínimo — nos
    # dois casos o anunciante precisa saber o que corrigir.
    add_column :ads, :moderation_note, :text
  end
end
