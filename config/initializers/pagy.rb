# Paginação das listagens (CMS interno e busca do mapa).
# 10 itens por página em todas as telas, salvo override explícito na chamada `pagy(...)`.
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:overflow] = :last_page # página fora do intervalo cai na última, não em erro
