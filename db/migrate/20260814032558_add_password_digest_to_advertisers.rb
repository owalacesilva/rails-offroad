require "bcrypt"

class AddPasswordDigestToAdvertisers < ActiveRecord::Migration[8.1]
  def up
    add_column :advertisers, :password_digest, :string

    backfill_unusable_digest

    change_column_null :advertisers, :password_digest, false
  end

  def down
    remove_column :advertisers, :password_digest
  end

  private
    # Os anunciantes semeados antes da autenticação precisam de um digest para a
    # coluna virar NOT NULL. Recebem uma senha aleatória que ninguém conhece —
    # ficam sem acesso até o seed (ou um reset) definir uma senha de verdade.
    def backfill_unusable_digest
      digest = BCrypt::Password.create(SecureRandom.hex(32))

      execute ActiveRecord::Base.sanitize_sql_array(
        [ "UPDATE advertisers SET password_digest = ? WHERE password_digest IS NULL", digest ]
      )
    end
end
