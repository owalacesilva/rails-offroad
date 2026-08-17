class AllowAdImagesWithoutFileUrl < ActiveRecord::Migration[8.1]
  # Com o upload pelo Dropzone a foto passa a ser um blob do Active Storage, e
  # a URL de exibição é derivada dele (ver AdImage#url). A coluna continua
  # existindo porque o seed e as fotos antigas apontam para /seed-images: as
  # duas origens convivem, e é o modelo que cobra ter pelo menos uma.
  def change
    change_column_null :ad_images, :file_url, true
  end
end
