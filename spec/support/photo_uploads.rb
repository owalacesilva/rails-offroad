require "tempfile"

# Fotos de verdade para os specs de upload.
#
# O AdPhotosController mede a imagem com a libvips antes de aceitá-la, então
# bytes falsos não servem: o PNG tem de abrir. Quem gera é o mesmo
# PlaceholderImage que o seed usa, sem gem de imagem e sem binário no repositório.
module PhotoUploadHelpers
  def png_bytes(width: 40, height: 30)
    PlaceholderImage.new(width: width, height: height, top: [ 220, 180, 120 ], bottom: [ 60, 40, 20 ]).to_png
  end

  # Arquivo como ele chega de um <input type="file">. Fica em disco porque a
  # controller lê o caminho do tempfile.
  def uploaded_png(filename: "foto.png", content_type: "image/png", **dimensions)
    file = Tempfile.new([ "foto", ".png" ], binmode: true)
    file.write(png_bytes(**dimensions))
    file.rewind

    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  # Blob já no storage, que é como o Dropzone deixa cada foto antes de o
  # formulário ser enviado.
  def photo_blob(filename: "foto.png")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(png_bytes), filename: filename, content_type: "image/png"
    )
  end

  def photo_signed_ids(count)
    Array.new(count) { |index| photo_blob(filename: "foto-#{index}.png").signed_id }
  end
end

RSpec.configure do |config|
  config.include PhotoUploadHelpers
end
