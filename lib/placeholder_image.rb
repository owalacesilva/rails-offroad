require "zlib"

# Gera um PNG de gradiente vertical sem depender de gem de imagem nem de arquivo
# no repositório. Existe para o seed conseguir anexar fotos de verdade no MinIO;
# quando houver upload real, isso some.
class PlaceholderImage
  SIGNATURE = "\x89PNG\r\n\x1A\n".b.freeze

  def initialize(width:, height:, top:, bottom:)
    @width = width
    @height = height
    @top = top
    @bottom = bottom
  end

  def to_png
    SIGNATURE +
      chunk("IHDR", header) +
      chunk("IDAT", Zlib::Deflate.deflate(scanlines)) +
      chunk("IEND", "")
  end

  private
    attr_reader :width, :height, :top, :bottom

    def header
      # 8 bits por canal, tipo 2 = RGB truecolor, sem entrelaçamento.
      [ width, height ].pack("N2") + [ 8, 2, 0, 0, 0 ].pack("C5")
    end

    def scanlines
      (0...height).map { |row| ([ 0 ] + (color_at(row) * width)).pack("C*") }.join
    end

    # Cada scanline abre com o byte de filtro 0 (None) — é o [0] acima.
    def color_at(row)
      ratio = height == 1 ? 0.0 : row.fdiv(height - 1)

      top.zip(bottom).map { |from, to| (from + ((to - from) * ratio)).round }
    end

    def chunk(type, data)
      body = type.b + data.b

      [ data.bytesize ].pack("N") + body + [ Zlib.crc32(body) ].pack("N")
    end
end
