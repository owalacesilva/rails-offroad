# Endereços das redes sociais do portal. Vêm do ambiente porque mudam por
# instalação e não são segredo: uma tabela seria mais uma migração para trocar
# um link, e um credential esconderia o que é público de propósito.
#
# Rede sem variável definida não aparece no rodapé. É assim que uma instalação
# sem canal no YouTube deixa de mostrar um ícone que não leva a lugar nenhum,
# em vez de apontar para "#".
class SocialLinks
  Link = Data.define(:key, :label, :url)

  # A ordem aqui é a ordem no rodapé. O rótulo é nome próprio da rede, não texto
  # traduzível — "WhatsApp" se escreve assim em qualquer idioma.
  NETWORKS = [
    { key: :instagram, label: "Instagram", variable: "SOCIAL_INSTAGRAM_URL" },
    { key: :youtube,   label: "YouTube",   variable: "SOCIAL_YOUTUBE_URL" },
    { key: :facebook,  label: "Facebook",  variable: "SOCIAL_FACEBOOK_URL" },
    { key: :whatsapp,  label: "WhatsApp",  variable: "SOCIAL_WHATSAPP_URL" }
  ].freeze

  # env é injetável para o spec não precisar mexer no ENV do processo.
  def self.all(env = ENV)
    NETWORKS.filter_map do |network|
      url = env[network[:variable]].to_s.strip

      Link.new(key: network[:key], label: network[:label], url: url) if url.present?
    end
  end
end
