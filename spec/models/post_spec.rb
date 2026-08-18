require "rails_helper"

RSpec.describe Post, type: :model do
  subject { build(:post) }

  it { is_expected.to belong_to(:admin) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body) }

  # Não há coluna de status: published_at diz tudo.
  describe "publicação" do
    it "sem data é rascunho" do
      expect(build(:post, :draft)).not_to be_published
    end

    it "com data no futuro está agendado, não publicado" do
      post = build(:post, :scheduled)

      expect(post).to be_scheduled
      expect(post).not_to be_published
    end

    it "com data no passado está publicado" do
      expect(build(:post)).to be_published
    end
  end

  describe "escopos" do
    it "published traz só o que já saiu, do mais novo para o mais velho" do
      older = create(:post, published_at: 10.days.ago)
      newer = create(:post, published_at: 1.day.ago)
      create(:post, :draft)
      create(:post, :scheduled)

      expect(described_class.published).to eq([ newer, older ])
    end

    it "drafts traz só o que não tem data" do
      draft = create(:post, :draft)
      create(:post)
      create(:post, :scheduled)

      expect(described_class.drafts).to eq([ draft ])
    end

    it "scheduled traz só o que ainda vai sair" do
      scheduled = create(:post, :scheduled)
      create(:post)
      create(:post, :draft)

      expect(described_class.scheduled).to eq([ scheduled ])
    end

    # As três abas da gestão não podem deixar post nenhum de fora.
    it "os três escopos particionam a tabela" do
      create(:post)
      create(:post, :draft)
      create(:post, :scheduled)

      counts = described_class.published.count + described_class.drafts.count + described_class.scheduled.count

      expect(counts).to eq(described_class.count)
    end
  end

  describe "slug" do
    it "deriva do título" do
      expect(create(:post, title: "Como escolher pneu de trilha").slug).to eq("como-escolher-pneu-de-trilha")
    end

    it "vai para a URL no lugar do id" do
      expect(create(:post, title: "Snorkel serve para quê").to_param).to eq("snorkel-serve-para-que")
    end

    it "desempata título repetido com sufixo" do
      create(:post, title: "Revisão pós-trilha")

      expect(create(:post, title: "Revisão pós-trilha").slug).to eq("revisao-pos-trilha-2")
    end

    # Renomear um post publicado não pode quebrar o link que ele já espalhou.
    it "não muda quando o título muda" do
      post = create(:post, title: "Título antigo")

      post.update!(title: "Título novo")

      expect(post.reload.slug).to eq("titulo-antigo")
    end
  end

  # O corpo é texto rico, limpo na entrada como a descrição do anúncio.
  describe "#body" do
    it "mantém as tags do editor" do
      expect(build(:post, body: "<h3>Motor</h3><ul><li>Item</li></ul>").body)
        .to eq("<h3>Motor</h3><ul><li>Item</li></ul>")
    end

    it "descarta tag fora da lista" do
      expect(build(:post, body: "<p>ok</p><iframe src='x'></iframe>").body).to eq("<p>ok</p>")
    end

    it "descarta atributo" do
      expect(build(:post, body: %(<p onclick="alert(1)">ok</p>)).body).to eq("<p>ok</p>")
    end
  end

  describe "#summary" do
    it "usa a chamada quando ela existe" do
      expect(build(:post, excerpt: "Resumo próprio").summary).to eq("Resumo próprio")
    end

    # O texto do card é texto, não HTML: as tags do corpo saem.
    it "corta o corpo sem as tags quando não há chamada" do
      post = build(:post, excerpt: nil, body: "<p>Primeiro <strong>parágrafo</strong>.</p>")

      expect(post.summary).to eq("Primeiro parágrafo.")
    end

    it "trunca no limite" do
      post = build(:post, excerpt: nil, body: "<p>#{'palavra ' * 100}</p>")

      expect(post.summary.length).to be <= described_class::SUMMARY_LENGTH
    end
  end

  describe "#cover" do
    it "aceita imagem http(s)" do
      expect(build(:post, :with_cover).cover).to eq("https://exemplo.com.br/capa.jpg")
    end

    it "recusa esquema fora de http(s) na validação" do
      expect(build(:post, cover_url: "javascript:alert(1)")).not_to be_valid
    end

    # Segunda barreira: vale para linha gravada por fora do modelo.
    it "devolve nil para qualquer outro esquema" do
      expect(build(:post, cover_url: "data:image/png;base64,AAA").cover).to be_nil
    end
  end
end
