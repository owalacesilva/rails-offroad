# O que fazer com o perfil que o provedor devolveu.
#
# Três desfechos, e o controller trata cada um: anunciante já conhecido (entra),
# anunciante novo (o cadastro continua no formulário, porque telefone, cidade e
# UF nenhum provedor informa) e conta já ligada a outra conta do mesmo provedor
# (recusa).
class OauthAuthentication
  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  # Primeiro pelo vínculo, depois pelo e-mail. O uid é o que não muda: alguém
  # que trocou o endereço no Google continua sendo a mesma pessoa aqui.
  def user
    return @user if defined?(@user)

    @user = user_by_identity || User.find_by(email: profile.email)
  end

  # Liga a conta do provedor ao anunciante. Recusa quando ele já ligou outra
  # conta do mesmo provedor — duas contas do Google no mesmo anunciante não é um
  # caso para resolver adivinhando qual vale.
  def connect(user)
    linked = identity_of(user)

    # Já ligado a esta conta do provedor: nada a fazer. Ligado a outra do mesmo
    # provedor: recusa.
    return linked.uid == @profile.uid if linked

    link(user)
  end

  private
    def user_by_identity
      OauthIdentity.find_by(provider: @profile.provider, uid: @profile.uid)&.user
    end

    def identity_of(user)
      user.oauth_identities.find_by(provider: @profile.provider)
    end

    def link(user)
      user.oauth_identities.create!(provider: @profile.provider, uid: @profile.uid)

      # O provedor já verificou o endereço; pedir confirmação por e-mail a quem
      # chegou por ele seria pedir duas vezes a mesma prova.
      user.confirm_email
    end
end
