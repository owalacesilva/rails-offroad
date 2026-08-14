require "rails_helper"

RSpec.describe Pagination do
  let(:category) { create(:category) }

  before { create_list(:listing, 5, category: category) }

  def paginate(page, per_page: 2)
    described_class.new(Listing.order(:id), page: page, per_page: per_page)
  end

  it "limita os registros ao tamanho da página" do
    expect(paginate(1).records.size).to eq(2)
  end

  it "calcula o total de páginas" do
    expect(paginate(1).total_pages).to eq(3)
  end

  it "corrige página acima do total para a última" do
    expect(paginate(999).page).to eq(3)
  end

  it "corrige página zero ou negativa para a primeira" do
    expect(paginate(-4).page).to eq(1)
  end

  it "trata página não numérica como a primeira" do
    expect(paginate("abacaxi").page).to eq(1)
  end

  it "informa o intervalo exibido" do
    pagination = paginate(2)

    expect([ pagination.from, pagination.to ]).to eq([ 3, 4 ])
  end

  it "fecha o intervalo no total na última página" do
    pagination = paginate(3)

    expect([ pagination.from, pagination.to ]).to eq([ 5, 5 ])
  end

  context "com escopo vazio" do
    before { Listing.delete_all }

    it "mantém uma página" do
      expect(paginate(1).total_pages).to eq(1)
    end

    it "zera o intervalo" do
      pagination = paginate(1)

      expect([ pagination.from, pagination.to ]).to eq([ 0, 0 ])
    end
  end

  it "conta corretamente mesmo com o escopo ordenado" do
    # ORDER BY em consulta agregada quebra no Postgres; o objeto remove a ordenação.
    scope = Listing.order(Arel.sql("listings.year DESC NULLS LAST"))

    expect(described_class.new(scope, page: 1).total_count).to eq(5)
  end
end
