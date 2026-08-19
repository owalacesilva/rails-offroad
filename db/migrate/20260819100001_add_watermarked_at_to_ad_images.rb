class AddWatermarkedAtToAdImages < ActiveRecord::Migration[8.1]
  def change
    # Nulo quer dizer "ainda não carimbada": é o que torna o job idempotente,
    # porque o ActiveJob repete a tentativa e a marca não pode sair dobrada.
    add_column :ad_images, :watermarked_at, :datetime
  end
end
