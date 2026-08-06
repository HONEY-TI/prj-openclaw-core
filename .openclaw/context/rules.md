# Regras

Regras e convencoes gerais que todos os agentes e skills devem seguir.
Fonte unica — skills usam `extends: ../../context/rules.md`, nao duplicam.

## Ordem de precedencia

1. rules.md (global, este arquivo)
2. agents/*.yaml (shared_rules por agente)
3. skills/*/SKILL.md (extends: aqui, apenas overrides especificos)

## Estilo de codigo — Clean Code

- Nomes descritivos, sem abreviacao obscura; funcao faz uma coisa so.
- Tipagem forte obrigatoria em toda linguagem que suportar (TS/Python/Go/etc);
  proibido `any`, `interface{}` generico ou equivalente sem justificativa.
- Sem codigo morto, comentado ou duplicado; extrair em funcao/modulo reutilizavel.
- Funcoes curtas, baixo nivel de aninhamento, early return no lugar de else aninhado.
- Efeitos colaterais explicitos; sem mutacao escondida de estado global.

## Comunicacao — sem verbosidade, sem narrar conformidade

- Proibido anunciar que vai seguir uma instrucao antes de agir
  (ex: "Entendido, vou seguir o formato...", "Let me execute...").
  A resposta a uma instrucao de formato/processo e APLICAR na proxima acao, nao anunciar.
- Se a proxima acao e uma chamada de ferramenta, ela vem direto, sem preambulo de texto.
- Excecao: uma frase curta de status operacional e aceitavel quando resume o que JA foi
  feito ou vai ser feito tecnicamente (ex: "PR #42 criado, iniciando commits"), nunca
  quando so repete/confirma uma regra do prompt.
- Respostas diretas e rapidas; sem preambulo, sem repeticao do que foi pedido.

## Execucao de comandos Bash

- A ferramenta de Bash recebe exclusivamente comandos Bash validos.
- Procurar usar sempre o mesmo bash, sem duplicar, sem criar um novo sempre.
- Proibido enviar XML, HTML ou qualquer marcacao (alem de markdown na comunicacao com o
  usuario) para dentro da ferramenta de Bash.
- Proibido envolver comandos em blocos de parametro/tag como se fossem parte do comando.
- Ao executar um comando longo, reportar validacao de progresso a cada 5s sem interromper
  a execucao (heartbeat em background), preferindo uma unica chamada de bash por tarefa.
- Usar apenas o mesmo bash, mantendo assim o historico, sem criar novo bash a cada comando.

## Git — proibicoes padrao (aplicam-se salvo skill dizer o contrario)

Por padrao nenhuma skill deve, salvo instrucao explicita do usuario:

- criar commit (incluindo commit vazio);
- criar branch temporaria;
- alterar arquivos fora do escopo pedido;
- usar stash;
- fazer squash;
- criar tags;
- modificar historico Git (rebase, reset --hard, force push);
- realizar merge manual;
- executar `git pull origin develop` ou qualquer pull automatico sem pedido explicito.

## Seguranca

- Nunca commitar segredo, chave de API ou credencial.
- Validar entrada externa antes de usar em comando de shell ou query.
- Preferir caminho absoluto e `assert_safe_path` (ou equivalente) antes de qualquer
  operacao destrutiva em arquivo.
