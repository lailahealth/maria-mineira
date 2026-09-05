---
name: chat-user-journey
description: Mapeia e avalia a jornada de usuária do chat /converse da Maria Mineira, e orienta mudanças que reduzam fricção sem comprometer segurança/honestidade. Use ao propor, revisar ou depurar qualquer mudança de fluxo, estágio, mensagem ou UI do chat.
---

# Jornada de usuária do chat (Maria Mineira)

Este projeto é um canal de informação e orientação para mulheres em situação de
violência doméstica em Minas Gerais. Quem usa o chat pode estar com medo, com
pressa, num celular emprestado, ou em risco imediato. A jornada não é um funil
de conversão — é uma conversa que precisa acolher, informar e nunca travar
quem só quer uma resposta rápida. Use esta skill sempre que for **propor,
revisar ou depurar** qualquer mudança de estágio, mensagem, card ou UI do chat.

## Antes de tudo: releia o código, não só este resumo

O mapa abaixo descreve o estado da jornada no momento em que esta skill foi
escrita. O código muda mais rápido do que este arquivo — **sempre releia os
arquivos citados antes de propor uma mudança**, em vez de confiar cegamente
nesta descrição:

- `app/services/chat/turn_handler.rb` — máquina de estágios, é aqui que a
  jornada realmente acontece.
- `app/controllers/chat/messages_controller.rb` — despacha cada requisição
  para o método certo de `TurnHandler` conforme `stage` e os params recebidos.
- `app/models/chat/conversation.rb` — enum de `stage`.
- `app/views/chat/conversations/_composer.html.erb` — o que a pessoa vê/pode
  fazer em cada estágio (isso é tão parte da jornada quanto o texto da IA).
- `app/views/chat/messages/_message.html.erb` — como cada `card_type` renderiza.
- `public/exemplos-chat.html` — roteiros de QA manual já existentes; ao mudar a
  jornada, atualize os cenários de lá também.

## Mapa da jornada hoje

1. **`saudacao`** → `TurnHandler#start!` manda a primeira mensagem e já vai
   para `aguardando_motivo`.
2. **`aguardando_motivo`** → `#receive_motivo`: classifica o texto
   (`Classification::Classifier`), checa sinais de emergência **antes de
   qualquer outra coisa** (`warn_emergency_if_needed`), responde a pergunta de
   verdade via `Chat::KnowledgeAnswerer` (`say_answer_or_fallback`), e vai
   direto para `livre` — **não força mais a busca de localização** aqui. A
   busca fica disponível a qualquer momento pelo botão "Buscar serviço perto
   de você" (ver `#request_location`), porque nem toda mulher que escreve quer
   buscar um serviço agora — às vezes só quer tirar uma dúvida.
3. **`livre`** → `#receive_free_text`: mesma checagem de emergência, depois
   tenta reconhecer se a mensagem inteira é uma localização (CEP ou nome de
   município, com tolerância a erro de digitação —
   `Territorial::LocationResolver#resolve_strict` +
   `Territorial::Municipality#fuzzy_match`) antes de tratar como pergunta.
   Isso existe porque mulheres digitam a cidade direto no chat em vez de usar
   o botão dedicado — se não reconhecer, ela recebe uma resposta "de bate-papo"
   em vez dos cards de serviço, o que já foi reportado como bug uma vez.
4. **`aguardando_localizacao`** → só alcançado via `#request_location`
   (clique no botão) ou pela detecção acima. Formulário dedicado: geolocalização
   do navegador ou campo de município/CEP. Tem uma saída
   (`#cancel_location_request`, botão "Voltar, só quero conversar") — todo
   estágio que tira o textarea de texto livre precisa de uma saída assim.
5. **`apresentando_resultado`** → depois de `#receive_location`: mostra
   `card_type: :facility_results` (com distância só quando veio de CEP/GPS,
   nunca de nome de cidade sozinho) ou `card_type: :municipio_sem_cobertura`
   (honesto: "ainda não temos informações suficientes", nunca inventa um
   resultado). Volta para texto livre em seguida.

## Princípios não-negociáveis (não proponha mudança que quebre isto)

- **Emergência sempre primeiro.** `warn_emergency_if_needed` roda antes de
  classificar ou responder qualquer coisa, em `receive_motivo` e
  `receive_free_text`. Mostra o card 190/180 no máximo uma vez por conversa.
  Qualquer novo tipo de turno precisa chamar isso também.
- **Honestidade sobre dado bonito.** Sem serviço cadastrado na região =
  mensagem clara dizendo isso, nunca um resultado forçado/genérico
  (`card_type: :municipio_sem_cobertura`). O mesmo vale para
  `Chat::KnowledgeAnswerer`: se a pergunta não é coberta pelo conteúdo das
  cartilhas, ele admite, não inventa (ver `persona_prompt` em
  `app/services/chat/knowledge_answerer.rb`).
- **Nunca cita a fonte do conteúdo.** As respostas da IA vêm das cartilhas do
  projeto Mulheres de Minas, mas nunca devem dizer isso — devem soar como
  conhecimento próprio da Maria Mineira.
- **Nada é passo obrigatório sem motivo.** Antes de forçar um novo estágio
  (tirar o textarea de texto livre), pergunte: "e se ela só quiser continuar
  conversando?" — foi exatamente esse o problema corrigido ao tirar a busca de
  localização forçada do fluxo principal.
- **Feedback de espera em toda chamada de IA.** `Chat::KnowledgeAnswerer` e o
  fallback de `Classification::LlmClassifier` são chamadas de rede síncronas
  que podem levar segundos — qualquer novo turno que dependa de IA precisa do
  indicador de "digitando" (`app/javascript/controllers/chat_typing_controller.js`,
  ligado a formulários que postam para `/mensagens`) ou equivalente.
- **Detecção de intenção é sempre rígida, nunca "contém".** Ver
  `Territorial::LocationResolver#resolve_strict`: reconhecer algo dentro de uma
  frase livre (localização, intenção, etc.) arrisca falso positivo. Prefira
  exigir que a mensagem inteira seja aquilo (com tolerância a erro de
  digitação quando fizer sentido) a tentar extrair de dentro de uma frase.

## Checklist ao avaliar ou propor uma mudança de jornada

Para cada mudança, responda:

1. **Fricção**: isso adiciona um passo obrigatório? Tem como pular/voltar?
2. **Segurança emocional**: o tom acolhe alguém com medo, sem soar clínico ou
   burocrático? Compare com as frases já existentes em `turn_handler.rb`.
3. **Honestidade**: em caso de dado ausente/incerto, a mensagem admite isso
   claramente, sem fingir um resultado?
4. **Mobile-first**: a maioria acessa pelo celular (ver os prints de produção
   já usados neste projeto) — teste em viewport estreito.
5. **Feedback de espera**: se depende de rede (IA, geocoding, CEP), a pessoa
   vê algo acontecendo enquanto espera?
6. **Reversibilidade**: dá para voltar/cancelar sem reiniciar a conversa
   inteira (`button_to chat_path, method: :delete`)?
7. **QA**: o cenário novo está coberto em `public/exemplos-chat.html`? Se não,
   adicione um cenário com entrada de teste e resultado esperado.

## Como verificar de verdade

Não basta ler o código — teste a conversa de ponta a ponta:

1. `bin/dev` (ou confirme que o server já está rodando) e abra `/converse`.
2. Passe pelo fluxo relevante manualmente, ou use Playwright headless (já
   usado neste projeto: `npx playwright install chromium`, depois um script
   Node simulando `page.fill`/`page.click` nos seletores do composer) para
   capturar screenshots do estado intermediário — é assim que se pega bugs de
   timing/estado que só aparecem no navegador real, não só lendo o código.
3. Clique em "Encerrar conversa" antes de repetir um teste (o estágio persiste
   por 1h — `Chat::Conversation::INACTIVITY_TIMEOUT`).
4. Depois de rodar `bin/rails tailwindcss:build` se mudou classes Tailwind
   novas e o watcher (`bin/dev`) não estiver rodando — sem isso, a classe nova
   não aparece no CSS compilado.
