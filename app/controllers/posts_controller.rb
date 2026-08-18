# Blog público. Só o que já foi publicado aparece: rascunho e post agendado
# ficam de fora pelo próprio escopo, sem coluna de status.
class PostsController < ApplicationController
  allow_unauthenticated_access

  PER_PAGE = 9

  # Quantos posts acompanham o que está sendo lido.
  RELATED_LIMIT = 3

  def index
    @pagination = Pagination.new(Post.published.includes(:admin), page: params[:page], per_page: PER_PAGE)
    @posts = @pagination.records
  end

  def show
    published = Post.published

    @post = published.includes(:admin).find_by!(slug: params[:id])
    @related = published.where.not(id: @post.id).limit(RELATED_LIMIT)
  end
end
