require "rails_helper"
require "tmpdir"

RSpec.describe BrazilianCities do
  let(:dir) { Pathname(Dir.mktmpdir) }
  let(:path) { dir.join("cities.csv") }

  after { FileUtils.remove_entry(dir) if dir.exist? }

  def write_file(*lines)
    path.write(([ described_class::HEADER ] + lines).join("\n") + "\n")
  end

  # O arquivo versionado, conferido sem inserir 5.571 linhas a cada rodada: se
  # o dado do IBGE for regerado errado, quebra aqui e não em produção.
  describe "db/cities.csv" do
    let(:entries) { described_class.entries }

    it "traz os 5.570 municípios mais Fernando de Noronha" do
      expect(entries.size).to eq(5_571)
    end

    it "cobre as 27 unidades da federação" do
      expect(entries.map { |entry| entry[:state] }.uniq).to match_array(User::BRAZILIAN_STATES)
    end

    it "não repete código do IBGE" do
      codes = entries.map { |entry| entry[:ibge_code] }

      expect(codes.uniq.size).to eq(codes.size)
    end

    # O índice único é (state, name) sob uma collation que ignora caixa e acento:
    # dois nomes que só diferem no acento colidiriam no banco, não aqui.
    it "não repete nome dentro do mesmo estado, nem ignorando acento e caixa" do
      pairs = entries.map { |entry| [ entry[:state], folded(entry[:name]) ] }

      expect(pairs.uniq.size).to eq(pairs.size)
    end

    it "traz as capitais que o restante do seed usa" do
      expect(entries).to include(
        { ibge_code: "4106902", name: "Curitiba", state: "PR" },
        { ibge_code: "3550308", name: "São Paulo", state: "SP" }
      )
    end

    def folded(name)
      name.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase
    end
  end

  describe ".import" do
    it "insere os municípios do arquivo" do
      write_file("4106902,Curitiba,PR", "3550308,São Paulo,SP")

      expect { described_class.import(path: path) }.to change(City, :count).by(2)
    end

    it "devolve o total de municípios na tabela" do
      write_file("4106902,Curitiba,PR")

      expect(described_class.import(path: path)).to eq(1)
    end

    # É o que deixa o db:seed rodar mais de uma vez, como o resto do arquivo.
    it "não duplica quando roda de novo" do
      write_file("4106902,Curitiba,PR")
      described_class.import(path: path)

      expect { described_class.import(path: path) }.not_to change(City, :count)
    end

    it "preserva o id do município já carregado" do
      write_file("4106902,Curitiba,PR")
      described_class.import(path: path)
      id = City.sole.id

      described_class.import(path: path)

      expect(City.sole.id).to eq(id)
    end

    # Município renomeado pelo IBGE é corrigido sem trocar de registro.
    it "atualiza o nome do município já carregado" do
      write_file("4106902,Curitiba Velha,PR")
      described_class.import(path: path)
      write_file("4106902,Curitiba,PR")

      described_class.import(path: path)

      expect(City.sole.name).to eq("Curitiba")
    end
  end

  # O parse é manual, sem a gem csv: as guardas abaixo são o que garante que uma
  # linha fora do formato estoure em vez de entrar torta no banco.
  describe "arquivo malformado" do
    it "recusa cabeçalho inesperado" do
      path.write("codigo,nome,uf\n4106902,Curitiba,PR\n")

      expect { described_class.entries(path: path) }.to raise_error(described_class::InvalidRow, /cabeçalho/)
    end

    it "recusa vírgula a mais na linha" do
      write_file("4106902,Curitiba, do Paraná,PR")

      expect { described_class.entries(path: path) }.to raise_error(described_class::InvalidRow)
    end

    it "recusa coluna faltando" do
      write_file("4106902,Curitiba")

      expect { described_class.entries(path: path) }.to raise_error(described_class::InvalidRow)
    end

    it "recusa código fora do formato do IBGE" do
      write_file("410,Curitiba,PR")

      expect { described_class.entries(path: path) }.to raise_error(described_class::InvalidRow)
    end

    it "ignora linha em branco no fim do arquivo" do
      path.write("#{described_class::HEADER}\n4106902,Curitiba,PR\n\n")

      expect(described_class.entries(path: path).size).to eq(1)
    end
  end
end
