# Carrega os municípios brasileiros de db/cities.csv para a tabela cities.
#
# O arquivo vem do IBGE (servicodados.ibge.gov.br/api/v1/localidades/municipios)
# e está versionado de propósito: a inicialização do projeto não pode depender de
# a API estar no ar, e o conteúdo muda uma vez a cada poucos anos.
#
# O parse é feito à mão, sem a gem csv. O `csv` deixou de ser default gem no Ruby
# 3.4 e teria de entrar no Gemfile, e o arquivo é gerado por nós, sempre com três
# colunas planas — nenhum nome de município tem vírgula, aspas ou quebra de linha.
# Linha que fuja disso estoura em vez de entrar torta no banco.
class BrazilianCities
  DATA_FILE = Rails.root.join("db/cities.csv")

  HEADER = "ibge_code,name,state".freeze

  # A forma exata de uma linha: código do IBGE, nome sem vírgula e UF. É a guarda
  # do parse manual — vírgula a mais ou a menos não passa por aqui —, e o código
  # segue o mesmo formato que a check constraint de cities.ibge_code exige.
  # Os grupos são nomeados porque viram as chaves do hash direto.
  ROW = /\A(?<ibge_code>[1-9]\d{6}),(?<name>[^,]+),(?<state>[A-Z]{2})\z/

  # As 5.571 linhas caberiam em um INSERT só dentro do max_allowed_packet padrão,
  # mas fatiar mantém cada statement legível no log lento e no binlog.
  BATCH_SIZE = 1_000

  class InvalidRow < StandardError; end

  def self.import(path: DATA_FILE)
    new(path).import
  end

  def self.entries(path: DATA_FILE)
    new(path).entries
  end

  def initialize(path = DATA_FILE)
    @path = Pathname(path)
  end

  # Idempotente: o índice único de ibge_code faz cada linha repetida cair no
  # ON DUPLICATE KEY UPDATE. Só nome e UF são atualizados, então um município
  # renomeado pelo IBGE é corrigido sem perder o id que outra tabela possa ter
  # guardado. Devolve o total de municípios na tabela.
  def import
    entries.each_slice(BATCH_SIZE) { |batch| upsert(batch) }

    City.count
  end

  # As linhas do arquivo como hashes, sem tocar no banco — é o que deixa um spec
  # conferir a integridade do dado sem inserir 5.571 registros.
  def entries
    lines = @path.readlines(chomp: true).reject(&:empty?)
    raise InvalidRow, "#{@path}: cabeçalho inesperado, era esperado #{HEADER.inspect}" unless lines.shift == HEADER

    # A partir de 2 porque a linha 1 é o cabeçalho: o erro sai como "arquivo:linha".
    lines.map.with_index(2) { |line, number| entry_from(line, number) }
  end

  private
    # O UUID é gerado aqui e não em `entries` porque upsert_all não passa pelos
    # callbacks do ApplicationRecord — ninguém preencheria a chave primária. Em
    # linha já existente ele é descartado: `id` não está em update_only.
    def upsert(batch)
      City.upsert_all(batch.map { |entry| entry.merge(id: SecureRandom.uuid) },
                      update_only: %i[name state], record_timestamps: true)
    end

    def entry_from(line, number)
      ROW.match(line)&.named_captures&.symbolize_keys ||
        raise(InvalidRow, "#{@path}:#{number}: linha fora do formato #{HEADER.inspect}")
    end
end
