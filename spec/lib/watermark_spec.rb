require "rails_helper"

RSpec.describe Watermark do
  # PlaceholderImage gera um gradiente vertical: dentro de uma mesma linha a cor
  # é constante. É isso que deixa os exemplos abaixo compararem dois pontos da
  # mesma altura e concluírem que só o meio da foto foi carimbado.
  let(:size) { { width: 400, height: 240 } }

  def source(format = ".png")
    Vips::Image.new_from_buffer(png_bytes(**size), "").write_to_buffer(format)
  end

  def stamp(format = ".png", content_type: "image/png")
    described_class.new(source(format), content_type: content_type).to_blob
  end

  def image(bytes)
    Vips::Image.new_from_buffer(bytes, "")
  end

  # Quantos pixels da faixa horizontal do meio mudaram. A faixa é diagonal e
  # esparsa — só o traço das letras marca —, então contar é mais firme do que
  # apostar num pixel específico.
  def row_of(bytes, row)
    image(bytes).crop(0, row, size[:width], 1).write_to_memory.unpack("C*")
  end

  def changed_in_middle(before, after)
    row = size[:height] / 2

    row_of(before, row).zip(row_of(after, row)).count { |was, is| was != is }
  end

  it "carimba a foto" do
    expect(changed_in_middle(source, stamp)).to be_positive
  end

  # Faixa única e centralizada: ela cruza o meio da foto, não um canto.
  it "põe a marca no meio, e não numa borda" do
    original = source
    stamped = stamp
    corner = ->(bytes) { image(bytes).crop(0, 0, 20, 20).write_to_memory.unpack("C*") }

    expect(changed_in_middle(original, stamped)).to be_positive
    expect(corner.call(stamped)).to eq(corner.call(original))
  end

  # Inclinada: se fosse horizontal, o traço cruzaria a mesma faixa de colunas em
  # qualquer altura. Em diagonal, o texto anda para a direita conforme sobe.
  it "escreve na diagonal" do
    original = source
    stamped = stamp
    ink = lambda do |row|
      was = row_of(original, row)
      is = row_of(stamped, row)
      columns = was.each_index.reject { |index| was[index] == is[index] }

      columns.sum.fdiv(columns.size)
    end

    # Centro de massa do traço mais acima, à direita do de mais abaixo.
    expect(ink.call(size[:height] / 3)).to be > ink.call(size[:height] * 2 / 3)
  end

  it "mantém as dimensões" do
    stamped = image(stamp)

    expect([ stamped.width, stamped.height ]).to eq(size.values)
  end

  # A foto tem de sair no formato em que entrou: é o content type do blob que
  # continua valendo depois da troca.
  it "devolve JPEG para quem entrou JPEG" do
    expect(image(stamp(".jpg", content_type: "image/jpeg")).get("vips-loader")).to start_with("jpeg")
  end

  it "devolve PNG para quem entrou PNG" do
    expect(image(stamp).get("vips-loader")).to start_with("png")
  end

  # JPEG não tem canal alfa, e o composite sempre devolve um: sem achatar, a
  # gravação estouraria.
  it "grava JPEG sem estourar no canal alfa" do
    expect { stamp(".jpg", content_type: "image/jpeg") }.not_to raise_error
  end

  # Melhor devolver a foto intacta do que reescrevê-la num formato que ninguém
  # pediu; quem chama trata o nil como "não carimbei".
  it "devolve nil para formato fora da lista" do
    expect(described_class.new(source, content_type: "image/gif").to_blob).to be_nil
  end

  # Foto larga e baixa: obedecer só à largura jogaria as pontas da faixa para
  # fora da imagem.
  it "encolhe a faixa para caber na foto baixa" do
    wide = Vips::Image.new_from_buffer(png_bytes(width: 400, height: 40), "").write_to_buffer(".png")

    expect(image(described_class.new(wide, content_type: "image/png").to_blob).height).to eq(40)
  end

  it "não estoura na foto miúda" do
    tiny = Vips::Image.new_from_buffer(png_bytes(width: 24, height: 18), "").write_to_buffer(".png")

    expect(described_class.new(tiny, content_type: "image/png").to_blob).to be_present
  end
end
