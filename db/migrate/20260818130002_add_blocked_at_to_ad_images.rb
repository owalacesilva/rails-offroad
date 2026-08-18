class AddBlockedAtToAdImages < ActiveRecord::Migration[8.1]
  def change
    # Foto barrada pela moderação. Timestamp e não booleano: além de dizer que
    # está bloqueada, registra quando — e nulo continua sendo "no ar".
    add_column :ad_images, :blocked_at, :datetime

    # As listagens públicas filtram por aqui em toda foto que exibem.
    add_index :ad_images, :blocked_at
  end
end
