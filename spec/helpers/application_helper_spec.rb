require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  # A régua é compartilhada pela vitrine e pelo blog, por isso mora aqui.
  describe "#paginated_page_numbers" do
    it "numera todas as páginas quando são poucas" do
      pagination = stub(total_pages: 4)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, 2, 3, 4 ])
    end

    it "some com a régua numerada quando são muitas" do
      pagination = stub(total_pages: described_class::MAX_NUMBERED_PAGES + 1)

      expect(helper.paginated_page_numbers(pagination)).to be_empty
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
