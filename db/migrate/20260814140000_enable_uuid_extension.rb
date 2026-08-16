# PostgreSQL 16 já traz gen_random_uuid() no core, mas pgcrypto mantém o schema
# carregável em instâncias mais antigas sem editar migração.
class EnableUuidExtension < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
  end
end
