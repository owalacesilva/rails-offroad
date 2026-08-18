require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  # A régua é compartilhada pela vitrine e pelo blog, por isso mora aqui.
  describe "#paginated_page_numbers" do
    it "numera todas as páginas quando são poucas" do
      pagination = stub(total_pages: 4)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, 2, 3, 4 ])
    end

    # Acima disso a régua vira primeira, janela em torno da atual e última, com
    # :gap onde há salto — é o que a view desenha como reticências.
    it "abre reticências no meio quando são muitas" do
      pagination = stub(total_pages: 20, page: 10)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, :gap, 9, 10, 11, :gap, 20 ])
    end

    it "não abre reticências à esquerda quando a atual é do começo" do
      pagination = stub(total_pages: 20, page: 2)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, 2, 3, :gap, 20 ])
    end

    it "não abre reticências à direita quando a atual é do fim" do
      pagination = stub(total_pages: 20, page: 19)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, :gap, 18, 19, 20 ])
    end

    it "sempre oferece a primeira e a última" do
      pagination = stub(total_pages: 50, page: 25)
      numbers = helper.paginated_page_numbers(pagination)

      expect(numbers.first).to eq(1)
      expect(numbers.last).to eq(50)
    end

    it "não repete número nem deixa gap grudado na borda" do
      pagination = stub(total_pages: 8, page: 4)
      numbers = helper.paginated_page_numbers(pagination)

      expect(numbers.count(1)).to eq(1)
      expect(numbers.first).not_to eq(:gap)
      expect(numbers.last).not_to eq(:gap)
    end
  end

  # Mesmo tratamento para a descrição do anúncio e para o corpo do post.
  describe "#rich_text" do
    it "mostra o HTML do editor como está" do
      expect(helper.rich_text("<h3>Motor</h3><ul><li>Pneu novo</li></ul>"))
        .to eq("<h3>Motor</h3><ul><li>Pneu novo</li></ul>")
    end

    it "descarta tag fora da lista" do
      expect(helper.rich_text("<p>ok</p><iframe src='x'></iframe>")).to eq("<p>ok</p>")
    end

    it "transforma linha em branco de texto puro em parágrafo" do
      expect(helper.rich_text("Um.\n\nDois.")).to eq("<p>Um.</p>\n\n<p>Dois.</p>")
    end

    # O sanitizador já escapou o & na entrada; escapar de novo daria "&amp;amp;".
    it "não escapa duas vezes o texto puro" do
      expect(helper.rich_text("Motor & câmbio")).to eq("<p>Motor &amp; câmbio</p>")
    end

    it "não devolve nada para conteúdo vazio" do
      expect(helper.rich_text(nil)).to be_nil
    end
  end
end
