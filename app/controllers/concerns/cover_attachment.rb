# Liga a capa enviada pelo formulário da gestão ao registro.
#
# O formulário manda `cover_signed_id`: preenchido, anexa o blob; vazio, remove
# a capa que existia. Ausente significa "não mexi nisso" — é o que deixa uma
# edição que não toca na imagem preservar a que já estava lá.
module CoverAttachment
  extend ActiveSupport::Concern

  private
    def attach_cover(record)
      signed_id = params.dig(record.model_name.param_key, :cover_signed_id)
      # Ausente é diferente de vazio: sem a chave, não se mexe na capa; com a
      # chave vazia, a capa é removida. String vazia é truthy em Ruby, então o
      # `unless` abaixo só barra o caso "não veio no formulário".
      return unless signed_id

      # purge e não purge_later: o later enfileira a remoção do blob mas não
      # desanexa na hora, e a capa continuaria aparecendo até o job rodar. É um
      # objeto pequeno só, então apagar dentro da requisição não pesa.
      signed_id.present? ? attach_blob(record, signed_id) : record.cover_image.purge
    end

    # find_signed devolve nil para id adulterado ou blob já removido, em vez de
    # estourar: aí a capa simplesmente não muda.
    def attach_blob(record, signed_id)
      blob = ActiveStorage::Blob.find_signed(signed_id)

      record.cover_image.attach(blob) if blob
    end
end
