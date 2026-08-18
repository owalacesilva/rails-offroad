require "rails_helper"

RSpec.describe Event, type: :model do
  subject { build(:event) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_presence_of(:starts_on) }
  it { is_expected.to validate_inclusion_of(:state).in_array(User::BRAZILIAN_STATES) }

  describe "intervalo de datas" do
    it "aceita evento de um dia, sem término" do
      expect(build(:event, ends_on: nil)).to be_valid
    end

    it "recusa término anterior ao início" do
      event = build(:event, starts_on: Date.current, ends_on: Date.current - 1.day)

      expect(event).not_to be_valid
      expect(event.errors[:ends_on]).to include(I18n.t("activerecord.errors.models.event.attributes.ends_on.before_start"))
    end

    it "a mesma regra vale no banco, não só no modelo" do
      event = build(:event, starts_on: Date.current, ends_on: Date.current - 1.day)

      expect { event.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe ".upcoming" do
    it "traz o que ainda vai começar" do
      event = create(:event)

      expect(described_class.upcoming).to include(event)
    end

    it "deixa de fora o que já passou" do
      expect(described_class.upcoming).not_to include(create(:event, :past))
    end

    # Encontro de três dias continua sendo notícia no segundo dia.
    it "mantém o que já começou e ainda não terminou" do
      expect(described_class.upcoming).to include(create(:event, :ongoing))
    end

    it "ordena do mais próximo para o mais distante" do
      later = create(:event, starts_on: 30.days.from_now.to_date)
      sooner = create(:event, starts_on: 5.days.from_now.to_date)

      expect(described_class.upcoming).to eq([ sooner, later ])
    end
  end

  # A gestão da agenda usa as duas listas; a home só usa upcoming.
  describe ".past" do
    it "traz o que já terminou" do
      expect(described_class.past).to include(create(:event, :past))
    end

    it "deixa de fora o que ainda vem" do
      expect(described_class.past).not_to include(create(:event))
    end

    it "deixa de fora o que começou e ainda não terminou" do
      expect(described_class.past).not_to include(create(:event, :ongoing))
    end

    # Ordem invertida: na gestão o que acabou de terminar é o que interessa.
    it "ordena do mais recente para o mais antigo" do
      older = create(:event, starts_on: 60.days.ago.to_date)
      recent = create(:event, starts_on: 5.days.ago.to_date)

      expect(described_class.past).to eq([ recent, older ])
    end

    it "não divide evento nenhum com upcoming" do
      create(:event)
      create(:event, :past)
      create(:event, :ongoing)

      expect(described_class.past.ids & described_class.upcoming.ids).to be_empty
    end
  end

  # Capa opcional do card na home, no mesmo esquema de #external_url.
  describe "#cover_url" do
    it "aceita imagem http(s)" do
      expect(build(:event, image_url: "https://exemplo.com.br/foto.jpg").cover_url)
        .to eq("https://exemplo.com.br/foto.jpg")
    end

    it "recusa esquema fora de http(s) na validação" do
      expect(build(:event, image_url: "javascript:alert(1)")).not_to be_valid
    end

    # Segunda barreira: vale para linha gravada por fora do modelo.
    it "devolve nil para qualquer outro esquema" do
      expect(build(:event, image_url: "data:image/png;base64,AAAA").cover_url).to be_nil
    end

    it "devolve nil quando não há imagem" do
      expect(build(:event, image_url: nil).cover_url).to be_nil
    end
  end

  describe "#single_day?" do
    it "é verdadeiro sem data de término" do
      expect(build(:event, ends_on: nil)).to be_single_day
    end

    it "é verdadeiro quando começa e termina no mesmo dia" do
      expect(build(:event, ends_on: Date.current, starts_on: Date.current)).to be_single_day
    end

    it "é falso quando dura mais de um dia" do
      expect(build(:event, :multi_day)).not_to be_single_day
    end
  end

  # O card da agenda transforma o endereço num href: esquema fora de http(s)
  # não pode chegar lá.
  describe "site do evento" do
    it "aceita http e https" do
      expect(build(:event, url: "https://exemplo.com.br/evento")).to be_valid
    end

    it "aceita evento sem site" do
      expect(build(:event, url: nil)).to be_valid
    end

    it "recusa outro esquema" do
      expect(build(:event, url: "javascript:alert(1)")).not_to be_valid
    end

    # O campo do formulário mostra "https://" como prefixo fixo, então o que é
    # digitado chega sem esquema.
    describe "esquema completado na escrita" do
      it "põe https:// no endereço digitado sem esquema" do
        expect(build(:event, url: "exemplo.com.br/evento").url).to eq("https://exemplo.com.br/evento")
      end

      it "não mexe no que já tem esquema" do
        expect(build(:event, url: "http://exemplo.com.br").url).to eq("http://exemplo.com.br")
      end

      # Completar aqui faria "javascript:alert(1)" virar um https:// qualquer e
      # passar pela validação que existe para barrá-lo.
      it "não completa esquema recusado" do
        expect(build(:event, url: "javascript:alert(1)").url).to eq("javascript:alert(1)")
      end

      # Dois-pontos seguido de número é porta, não esquema.
      it "completa endereço com porta" do
        expect(build(:event, url: "exemplo.com.br:8080/evento").url).to eq("https://exemplo.com.br:8080/evento")
      end

      it "deixa em branco o que veio em branco" do
        expect(build(:event, url: "").url).to eq("")
      end
    end

    describe "#external_url" do
      it "devolve a URL quando ela é http(s)" do
        expect(build(:event, :with_url).external_url).to eq("https://exemplo.com.br/evento")
      end

      # Segunda barreira: vale mesmo para linha gravada direto por SQL.
      it "devolve nil para qualquer outro esquema" do
        expect(build(:event, url: "javascript:alert(1)").external_url).to be_nil
      end

      it "devolve nil quando não há site" do
        expect(build(:event, url: nil).external_url).to be_nil
      end
    end
  end

  describe "#location" do
    it "junta cidade e UF" do
      expect(build(:event, city: "Cuiabá", state: "MT").location).to eq("Cuiabá, MT")
    end
  end
end
