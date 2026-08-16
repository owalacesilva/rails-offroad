# O namespace se chama Moderation, não Admin, porque `Admin` já é o modelo —
# uma constante não pode ser classe e módulo ao mesmo tempo. As URLs e os
# helpers de rota continuam sendo /admin e admin_*.
module Moderation
  # Dispensa a sessão de anunciante e exige a de moderador no lugar dela.
  class BaseController < ApplicationController
    allow_unauthenticated_access

    include AdminAuthentication

    layout "admin"
  end
end
