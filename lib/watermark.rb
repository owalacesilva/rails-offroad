# Carimba o nome do portal, na diagonal, sobre a foto de um anúncio.
#
# Uma faixa só, girada e centralizada, dimensionada em fração da foto — pesa o
# mesmo numa foto grande e numa pequena, e atravessa o assunto em vez de ficar
# num canto de onde sairia com um corte.
#
# Trabalha em bytes, não em arquivo: quem chama é AdImage#apply_watermark, que
# baixa o blob do Active Storage e sobe o resultado no lugar.
class Watermark
  # Quanto da foto a faixa ocupa, e a inclinação em graus.
  SCALE = 0.72
  ANGLE = 30
  OPACITY = 0.5

  # Sem família: é a "sans bold" que o fontconfig resolver, hoje a DejaVu Sans
  # do pacote fonts-dejavu-core (fixado nos dois Dockerfiles justamente por
  # isto). A Montserrat do portal não serve aqui — os arquivos em
  # app/assets/fonts são woff2, que o FreeType desta imagem não descomprime, e
  # o pango cai de volta na padrão sem avisar. O corpo é irrelevante: o texto é
  # gerado grande e reduzido depois.
  FONT = "sans bold 12"

  # Sufixo de saída por content type — é pelo sufixo que a libvips escolhe o
  # codificador. A lista é a mesma que PhotoUpload aceita na entrada, e é ela
  # que garante que a foto sai no formato em que entrou.
  FORMATS = {
    "image/jpeg" => ".jpg[Q=88]",
    "image/png" => ".png",
    "image/webp" => ".webp[Q=88]"
  }.freeze

  def initialize(bytes, content_type:)
    @bytes = bytes
    @content_type = content_type
  end

  # Os bytes carimbados, ou nil para formato fora da lista: devolver a foto
  # intacta é melhor do que reescrevê-la num formato que ninguém pediu.
  def to_blob
    format = FORMATS[@content_type]

    stamped.write_to_buffer(format) if format
  end

  private
    def stamped
      apply(Vips::Image.new_from_buffer(@bytes, "").colourspace(:srgb))
    end

    # JPEG e WebP não têm canal alfa e o composite sempre devolve um; gravar
    # assim estouraria. Foto que já tinha transparência mantém a sua.
    def apply(photo)
      composed = place(photo, mark_for(photo))

      photo.has_alpha? ? composed : composed.flatten(background: 255)
    end

    # Duas cópias da mesma faixa: uma preta, deslocada, que faz de sombra, e a
    # branca por cima. A sombra não é enfeite — o carimbo é igual em toda foto,
    # ninguém escolhe a cor olhando o fundo, e sem ela o texto branco sumiria
    # numa foto clara.
    def place(photo, mark)
      left, top = offsets(photo, mark)

      photo.composite([ tint(mark, 0), tint(mark, 255) ], :over, x: left, y: top)
    end

    # Faixa centralizada, e a cópia da sombra alguns pixels abaixo e à direita.
    # Cada eixo devolve o par na mesma ordem em que as duas cópias entram no
    # composite: sombra primeiro, texto por cima.
    def offsets(photo, mark)
      width = photo.width
      drop = [ (width * 0.003).round, 1 ].max
      left = ((width - mark.width) / 2.0).round
      top = ((photo.height - mark.height) / 2.0).round

      [ [ left + drop, left ], [ top + drop, top ] ]
    end

    # A faixa nasce como máscara de uma banda (0 a 255); aqui ela vira imagem
    # colorida com a própria máscara, esmaecida, no canal alfa.
    def tint(mask, level)
      mask.new_from_image([ level ] * 3).bandjoin(mask * OPACITY).copy(interpretation: :srgb)
    end

    # O texto é gerado grande e reduzido só depois de girar, para a faixa ficar
    # com a medida pedida já inclinada — girar depois mudaria o tamanho de novo.
    def mark_for(photo)
      rotated = text_mask.rotate(-ANGLE, background: 0)

      rotated.resize(fit(photo, rotated))
    end

    # Cabe pela largura e pela altura: numa foto larga e baixa, obedecer só à
    # largura jogaria as pontas da faixa para fora da imagem.
    def fit(photo, mark)
      [ photo.width.fdiv(mark.width), photo.height.fdiv(mark.height) ].min * SCALE
    end

    # O nome sai sempre do locale padrão: o que fica gravado no pixel não pode
    # depender do idioma de quem estava logado quando o job rodou.
    def text_mask
      Vips::Image.text(I18n.t("layout.header.brand", locale: I18n.default_locale), font: FONT, dpi: 600)
    end
end
