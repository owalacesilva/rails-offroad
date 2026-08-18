require "rails_helper"

RSpec.describe Ad, type: :model do
  subject { build(:ad) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:admin).optional }
  it { is_expected.to have_many(:proposals).dependent(:destroy) }
  it { is_expected.to have_many(:ad_images).dependent(:destroy) }
  it { is_expected.to have_many(:technical_spec_values).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_length_of(:state).is_equal_to(2) }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  it "nomeia o badge de novidade como new_arrival para não colidir com Ad.new" do
    expect(described_class.badges.keys).to contain_exactly("prepared", "featured", "new_arrival")
  end

  # A coluna é price_cents (inteiro); a aplicação inteira fala em reais.
  describe "#price" do
    it "lê de volta em reais o que foi gravado em reais" do
      expect(build(:ad, price: 389_900).price).to eq(389_900)
    end

    it "guarda centavos inteiros na coluna" do
      expect(build(:ad, price: 389_900).price_cents).to eq(38_990_000)
    end

    it "preserva as duas casas decimais" do
      expect(create(:ad, price: 8_790.50).reload.price).to eq(8_790.50)
    end

    it "aceita o formato brasileiro que o formulário manda" do
      expect(build(:ad, price: "45.000,50").price_cents).to eq(4_500_050)
    end

    # Sem isso o formulário voltaria com o campo vazio depois do erro.
    it "devolve o texto cru quando ele não vira número" do
      ad = build(:ad, price: "a combinar")

      expect(ad).not_to be_valid
      expect(ad.price).to eq("a combinar")
    end
  end

  # A URL do anúncio é a slug, derivada do título.
  describe "slug" do
    it "deriva do título" do
      expect(create(:ad, title: "Jeep Wrangler Rubicon 3.6 V6").slug).to eq("jeep-wrangler-rubicon-3-6-v6")
    end

    it "vai para a URL no lugar do id" do
      ad = create(:ad, title: "Troller T4 3.2")

      expect(ad.to_param).to eq("troller-t4-3-2")
    end

    it "desempata título repetido com sufixo" do
      create(:ad, title: "Jeep Wrangler")

      expect(create(:ad, title: "Jeep Wrangler").slug).to eq("jeep-wrangler-2")
    end

    # Gerada uma vez: renomear um anúncio publicado não pode quebrar o link
    # que ele já espalhou.
    it "não muda quando o título muda" do
      ad = create(:ad, title: "Jeep Wrangler")

      ad.update!(title: "Jeep Wrangler Rubicon")

      expect(ad.reload.slug).to eq("jeep-wrangler")
    end

    it "é única no próprio banco" do
      create(:ad, title: "Jeep Wrangler")
      duplicate = build(:ad, title: "Outro", slug: "jeep-wrangler")

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "ano" do
    it "aceita anúncio sem ano" do
      expect(build(:ad, :without_year)).to be_valid
    end

    it "aceita o ano corrente" do
      expect(build(:ad, year: Date.current.year)).to be_valid
    end

    # O teto é o ano corrente: nada de modelo-ano adiantado, que era o que o
    # limite anterior (ano + 1) permitia.
    it "recusa o ano que vem" do
      expect(build(:ad, year: Date.current.year + 1)).not_to be_valid
    end

    it "recusa ano no futuro distante" do
      expect(build(:ad, year: Date.current.year + 5)).not_to be_valid
    end

    it "recusa ano anterior ao automóvel" do
      expect(build(:ad, year: 1899)).not_to be_valid
    end
  end

  # A descrição chega como HTML do editor do formulário e é limpa na entrada:
  # o banco só guarda o que está dentro de DESCRIPTION_TAGS.
  describe "descrição" do
    it "mantém as tags que o editor produz" do
      ad = build(:ad, description: "<h3>Motor</h3><p>Revisado e <strong>impecável</strong>.</p><ul><li>Pneu novo</li></ul>")

      expect(ad.description).to eq("<h3>Motor</h3><p>Revisado e <strong>impecável</strong>.</p><ul><li>Pneu novo</li></ul>")
    end

    it "descarta tag fora da lista" do
      expect(build(:ad, description: "<p>ok</p><iframe src='x'></iframe>").description).to eq("<p>ok</p>")
    end

    it "descarta atributo, inclusive evento de clique" do
      expect(build(:ad, description: %(<p onclick="alert(1)" class="x">ok</p>)).description).to eq("<p>ok</p>")
    end

    it "descarta link, que o editor não oferece" do
      expect(build(:ad, description: %(<p>veja <a href="http://x">aqui</a></p>)).description).to eq("<p>veja aqui</p>")
    end

    # Texto puro é o que o seed grava e o que sobra sem JavaScript: atravessa
    # sem virar HTML.
    it "deixa texto puro em paz" do
      ad = build(:ad, description: "Bem conservado.\n\nAceito troca.")

      expect(ad.description).to eq("Bem conservado.\n\nAceito troca.")
    end

    it "aceita descrição vazia" do
      expect(build(:ad, description: nil)).to be_valid
    end
  end

  # "Selecione todos os atributos": o conjunto exigido é o da categoria.
  describe "especificações obrigatórias" do
    let(:category) { create(:category, :vehicles) }
    let(:engine) { create(:spec_attribute, name: "engine", position: 3) }

    before { create(:attribute_category, category: category, spec_attribute: engine) }

    def submit(ad)
      ad.valid?(:submission)
      ad
    end

    it "recusa a submissão sem a especificação que a categoria pede" do
      ad = build(:ad, category: category)

      expect(submit(ad).errors[:base].join).to include(engine.label)
    end

    it "aceita a submissão com todas preenchidas" do
      ad = build(:ad, category: category)
      ad.technical_spec_values.build(spec_attribute: engine, value: "3.6 V6")

      expect(ad.valid?(:submission)).to be(true)
    end

    it "não aceita valor em branco como preenchido" do
      ad = build(:ad, category: category)
      ad.technical_spec_values.build(spec_attribute: engine, value: "")

      expect(submit(ad).errors[:base]).not_to be_empty
    end

    # Fora da submissão pelo formulário nada disso é cobrado — é o que deixa o
    # seed e a moderação trabalharem com anúncio incompleto.
    it "não cobra nada fora do contexto de submissão" do
      expect(build(:ad, category: category)).to be_valid
    end
  end

  it "barra preço não positivo no próprio banco" do
    # A slug vem de um before_validation, que save!(validate: false) pula: sem
    # ela o INSERT esbarraria no NOT NULL antes de chegar à check constraint.
    ad = build(:ad, price: 0, slug: "preco-invalido")

    expect { ad.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /ads_price_positive/)
  end

  describe "status" do
    it "nasce pendente quando não informado" do
      expect(described_class.new.status).to eq("pending")
    end

    it "barra status fora da lista no próprio banco" do
      ad = build(:ad)
      ad.save!

      expect { described_class.connection.execute("UPDATE ads SET status = 'inventado' WHERE id = '#{ad.id}'") }
        .to raise_error(ActiveRecord::StatementInvalid, /ads_status_valid/)
    end

    it "published traz só os aprovados" do
      approved = create(:ad)
      create(:ad, :pending)
      create(:ad, :rejected)

      expect(described_class.published).to eq([ approved ])
    end

    # Bloquear um anunciante tira os anúncios dele do ar sem mexer em cada um.
    it "published deixa de fora o anúncio de anunciante bloqueado" do
      create(:ad, user: create(:user, status: :blocked))

      expect(described_class.published).to be_empty
    end

    it "published deixa de fora o anúncio de anunciante inativo" do
      create(:ad, user: create(:user, status: :inactive))

      expect(described_class.published).to be_empty
    end
  end

  describe "quantidade de fotos" do
    it "exige ao menos o mínimo em anúncio aprovado" do
      expect(build(:ad, image_count: described_class::IMAGE_COUNT.min - 1)).not_to be_valid
    end

    it "recusa mais que o máximo em anúncio aprovado" do
      expect(build(:ad, image_count: described_class::IMAGE_COUNT.max + 1)).not_to be_valid
    end

    it "não cobra fotos de rascunho" do
      expect(build(:ad, :draft)).to be_valid
    end
  end

  describe "#approve" do
    let(:admin) { create(:admin) }

    it "registra quem avaliou e publica" do
      ad = create(:ad, :pending, image_count: 3)

      expect(ad.approve(admin)).to be(true)
      expect(ad.reload).to have_attributes(status: "approved", admin: admin)
      expect(ad.published_at).to be_present
    end

    it "não aprova anúncio sem as fotos mínimas" do
      ad = create(:ad, :pending)

      expect(ad.approve(admin)).to be(false)
      expect(ad.reload.status).to eq("pending")
    end
  end

  describe "#reject" do
    it "registra quem avaliou sem publicar" do
      admin = create(:admin)
      ad = create(:ad, :pending)

      expect(ad.reject(admin)).to be(true)
      expect(ad.reload).to have_attributes(status: "rejected", admin: admin)
    end
  end

  describe "escopos" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }

    it "by_category filtra pelo slug" do
      wrangler = create(:ad, category: vehicles)
      create(:ad, category: parts)

      expect(described_class.by_category("veiculos-4x4")).to eq([ wrangler ])
    end

    it "recent ordena da publicação mais nova para a mais antiga" do
      older = create(:ad, category: vehicles, published_at: 3.days.ago)
      newer = create(:ad, category: vehicles, published_at: 1.day.ago)

      expect(described_class.recent).to eq([ newer, older ])
    end

    it "most_viewed ordena pelo contador de visualizações" do
      quiet = create(:ad, category: vehicles, views_count: 2)
      popular = create(:ad, category: vehicles, views_count: 500)

      expect(described_class.most_viewed).to eq([ popular, quiet ])
    end

    # Acervo novo tem todo mundo zerado; sem desempate a ordem seria indefinida.
    it "most_viewed desempata pela publicação mais recente" do
      older = create(:ad, category: vehicles, published_at: 3.days.ago, views_count: 0)
      newer = create(:ad, category: vehicles, published_at: 1.day.ago, views_count: 0)

      expect(described_class.most_viewed).to eq([ newer, older ])
    end
  end

  describe "#record_view" do
    it "soma uma visualização" do
      ad = create(:ad, views_count: 4)

      expect { ad.record_view }.to change { ad.reload.views_count }.from(4).to(5)
    end

    # É contador, não edição do anúncio: um UPDATE direto na coluna, sem
    # validação nem callback — inclusive o de timestamp.
    it "não remarca updated_at" do
      ad = create(:ad)
      updated_at = ad.updated_at

      ad.record_view

      expect(ad.reload.updated_at).to eq(updated_at)
    end
  end

  describe "#ordered_specifications" do
    let(:ad) { create(:ad) }

    def add_spec(name, value, position:, data_type: "STRING")
      attribute = create(:spec_attribute, name: name, position: position, data_type: data_type)
      create(:technical_spec_value, ad: ad, spec_attribute: attribute, value: value)
    end

    it "segue a coluna position do atributo, não a ordem de inserção" do
      add_spec("color", "Verde", position: 9)
      add_spec("condition", "Usado", position: 1)
      add_spec("engine", "3.6 V6", position: 3)

      expect(ad.reload.ordered_specifications.map(&:first)).to eq(%w[condition engine color])
    end

    it "converte o valor conforme o data_type do atributo" do
      add_spec("mileage_km", "48000", position: 2, data_type: "INT")

      expect(ad.reload.ordered_specifications).to eq([ [ "mileage_km", 48_000 ] ])
    end

    it "devolve vazio quando o anúncio não tem especificação" do
      expect(ad.ordered_specifications).to be_empty
    end
  end

  describe "#related" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }
    let(:ad) { create(:ad, category: vehicles, published_at: 1.hour.ago) }

    it "traz outro anúncio da mesma categoria" do
      sibling = create(:ad, category: vehicles)

      expect(ad.related).to contain_exactly(sibling)
    end

    it "não inclui o próprio anúncio" do
      create(:ad, category: vehicles)

      expect(ad.related).not_to include(ad)
    end

    it "ignora anúncio de outra categoria" do
      create(:ad, category: parts)

      expect(ad.related).to be_empty
    end

    it "ignora anúncio que ainda não foi aprovado" do
      create(:ad, :pending, category: vehicles)

      expect(ad.related).to be_empty
    end

    it "respeita o limite" do
      create_list(:ad, 6, category: vehicles)

      expect(ad.related.size).to eq(described_class::RELATED_LIMIT)
    end

    it "ordena do mais recente para o mais antigo" do
      older = create(:ad, category: vehicles, published_at: 5.days.ago)
      newer = create(:ad, category: vehicles, published_at: 1.day.ago)

      expect(ad.related.to_a).to eq([ newer, older ])
    end
  end
end
