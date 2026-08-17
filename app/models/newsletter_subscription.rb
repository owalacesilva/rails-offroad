# Inscrição na newsletter do portal. Só o e-mail: quem se inscreve pelo bloco da
# home não tem conta nem precisa criar uma.
class NewsletterSubscription < ApplicationRecord
  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Reinscrever com um e-mail que já está na lista não é erro do visitante: ele
  # continua inscrito, que é o que ele pediu. Devolve o registro existente em
  # vez de um objeto inválido para a controller não ter de distinguir os dois.
  def self.subscribe(email, source: nil)
    normalized = normalize_value_for(:email, email)

    find_by(email: normalized) || insert_or_find(normalized, source)
  end

  # create_or_find_by não serve aqui: com a validação de unicidade declarada, o
  # INSERT duplicado nem chega ao banco — ele volta como registro inválido, e o
  # RecordNotUnique que aquele método espera nunca acontece.
  #
  # O rescue cobre o duplo clique: entre o find_by acima e este INSERT cabe
  # outra requisição, e aí quem barra é o índice único, não a validação.
  def self.insert_or_find(email, source)
    create(email: email, source: source)
  rescue ActiveRecord::RecordNotUnique
    find_by(email: email)
  end
  private_class_method :insert_or_find
end
