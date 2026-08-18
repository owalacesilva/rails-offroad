class AddConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def up
    # Nulo é "ainda não confirmou o e-mail". Não virou mais um valor de
    # users.status porque as duas coisas são independentes: a moderação bloqueia
    # quem já confirmou, e quem confirmou pode ser bloqueado depois.
    add_column :users, :confirmed_at, :datetime

    # SQL direto e não o modelo: migração que carrega classe da aplicação quebra
    # quando o modelo muda depois.
    #
    # Quem já estava cadastrado não pode ser trancado para fora por uma regra
    # que passou a existir hoje — a data de criação vale como confirmação.
    execute "UPDATE users SET confirmed_at = created_at"
  end

  def down
    remove_column :users, :confirmed_at
  end
end
