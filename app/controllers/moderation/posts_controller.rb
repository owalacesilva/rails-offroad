module Moderation
  # Gestão do blog. Post é conteúdo do portal, escrito pela equipe: quem cria,
  # edita e apaga é a moderação, e não há fila de aprovação.
  #
  # Não há coluna de status — quem separa as três listas é `published_at`:
  # nulo é rascunho, no futuro é agendado, no passado é publicado.
  class PostsController < BaseController
    include CoverAttachment

    POST_FIELDS = %i[title excerpt body cover_url published_at].freeze

    SCOPES = %w[published scheduled drafts].freeze

    def index
      @scope = requested_scope
      @posts = Post.public_send(@scope).includes(:admin)
      @counts = SCOPES.index_with { |scope| Post.public_send(scope).count }
    end

    def new
      @post = Post.new
    end

    def create
      # O autor é quem está com a sessão de moderador aberta; o formulário não
      # oferece esse campo.
      @post = current_admin.posts.new(post_params)

      return render :new, status: :unprocessable_content unless @post.save

      attach_cover(@post)

      redirect_to admin_posts_path, notice: t("admin.posts.create.success", title: @post.title)
    end

    def edit
      @post = find_post
    end

    def update
      @post = find_post

      return render :edit, status: :unprocessable_content unless @post.update(post_params)

      attach_cover(@post)

      redirect_to admin_posts_path(scope: requested_scope),
                  notice: t("admin.posts.update.success", title: @post.title)
    end

    def destroy
      post = find_post
      post.destroy

      redirect_to admin_posts_path, notice: t("admin.posts.destroy.success", title: post.title)
    end

    private
      def find_post
        Post.find_by!(slug: params[:id])
      end

      # Aba desconhecida na URL cai nos publicados, que é a lista principal.
      def requested_scope
        requested = params[:scope]

        SCOPES.include?(requested) ? requested : SCOPES.first
      end

      def post_params
        params.expect(post: POST_FIELDS)
      end
  end
end
