namespace :active_storage do
  desc "Remove blobs que nunca foram anexados (formulário de anúncio abandonado)."
  task purge_unattached: :environment do
    # O Dropzone sobe cada foto assim que ela é escolhida, mas quem liga a foto
    # ao anúncio é o envio do formulário. Quem desiste no meio deixa o blob no
    # MinIO sem dono, e nada no Rails recolhe isso sozinho.
    #
    # A folga de um dia é o que separa "abandonado" de "o anunciante ainda está
    # preenchendo o formulário nesta aba".
    cutoff = 1.day.ago
    scope = ActiveStorage::Blob.unattached.where(created_at: ...cutoff)

    total = scope.count
    scope.find_each(&:purge_later)

    puts "Blobs sem dono enfileirados para remoção: #{total}."
  end
end
