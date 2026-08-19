# Foto de um anúncio. A ordem é a coluna sort_order, explícita, que é o motivo
# de a tabela existir em vez de um has_many_attached solto.
#
# A foto vem de uma de duas origens: um blob do Active Storage, quando o
# anunciante subiu o arquivo pelo formulário, ou uma URL pronta em `file_url`,
# que é como o seed aponta para /seed-images. As duas convivem — #url escolhe.
class AdImage < ApplicationRecord
  belongs_to :ad

  has_one_attached :file

  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :source_present

  scope :ordered, -> { order(:sort_order, :created_at) }
  # Foto bloqueada pela moderação some do portal inteiro; a gestão continua
  # vendo para poder desbloquear.
  scope :visible, -> { where(blocked_at: nil) }
  scope :blocked, -> { where.not(blocked_at: nil) }

  # De onde a foto é exibida.
  def url
    return file_url unless file.attached?

    attachment_path(file)
  end

  def blocked?
    blocked_at.present?
  end

  # Carimba a marca do portal e troca o blob pelo resultado. Devolve se
  # carimbou — sem "!", porque nada aqui estoura quando não dá para carimbar.
  #
  # Idempotente pela coluna watermarked_at, porque o ActiveJob repete a
  # tentativa e a marca não pode sair dobrada. Foto que veio de `file_url` (o
  # seed aponta para /seed-images) não tem blob para reescrever e passa direto,
  # assim como formato que o Watermark não conhece.
  def apply_watermark
    attachment = file

    return false if watermarked_at.present? || !attachment.attached?

    stamped = Watermark.new(attachment.download, content_type: attachment.content_type).to_blob

    stamped ? replace_file(attachment, stamped) : false
  end

  private
    # O blob é criado e enviado antes do attach, como no upload do formulário
    # (ver PhotoUpload#store_photo). Passar o `io:` direto para o attach adiaria
    # o envio para o after_commit, e aí a foto carimbada não existiria no
    # storage dentro de uma transação — que é onde cada exemplo da suíte roda.
    # Blob que fica sem dono por falha no meio do caminho é o que a tarefa
    # `active_storage:purge_unattached` recolhe.
    #
    # Nome e content type saem do anexo atual, ainda o original neste ponto; o
    # attach põe o blob novo no lugar e manda o antigo para o purge.
    #
    # O update! vem depois e não antes: o attach só grava sozinho num registro
    # sem outras mudanças pendentes, então marcar a data primeiro deixaria a
    # troca do arquivo sem ser salva.
    def replace_file(attachment, bytes)
      file.attach(stamped_blob(attachment, bytes))
      update!(watermarked_at: Time.current)

      true
    end

    def stamped_blob(attachment, bytes)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(bytes), filename: attachment.filename.to_s, content_type: attachment.content_type
      )
    end

    # Uma das duas origens tem que existir; qual delas é indiferente.
    def source_present
      return if file_url.present? || file.attached?

      errors.add(:base, :missing_file)
    end
end
