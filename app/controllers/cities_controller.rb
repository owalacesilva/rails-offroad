# Autocomplete de municípios, consumido pelo formulário de anúncio.
#
# Existe para o formulário não carregar os 5.571 municípios de uma vez: o
# navegador pede só os que casam com a UF escolhida e com o que já foi digitado.
class CitiesController < ApplicationController
  allow_unauthenticated_access

  # Quantos cabem na lista sem virar rolagem infinita. Quem não achou o
  # município nos dez primeiros digita mais uma letra.
  LIMIT = 10

  def index
    render json: suggestions
  end

  private
    # Só os nomes: `ads.city` guarda o nome, não o id do município.
    def suggestions
      City.by_state(state).matching(query).ordered.limit(LIMIT).pluck(:name)
    end

    # UF fora da lista simplesmente não casa com nada e devolve [] — não é erro
    # do usuário, é um estado ainda não escolhido.
    def state
      params[:state].to_s.upcase
    end

    # Sem termo, devolve os primeiros do estado em ordem alfabética: é o que
    # popula a lista assim que a UF é escolhida.
    def query
      params[:q].to_s.strip
    end
end
