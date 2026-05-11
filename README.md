# DAVIBOT

Bot para o discord
---

## Sobre

O Davibot é um bot para o discord. A finalidade dele inicial é para um trabalho da disciplina de programação funcional, logo apesar do nome humorístico, alguns comandos são engraçados, outros não.
Acredita-se que o repo pode ser desenvolvido após a avaliação do trabalho no tempo livre do desenvolvedor (se ele quiser sim mano). 

## 1. 🚀 Funcionalidades

### 1.1 Moderação
Ferramentas administrativas para manutenção da ordem e segurança do ambiente digital.
- **!kick:** Expulsa membros do servidor com suporte a justificativa personalizada via logs.
- **!roleta-russa:** Comando de moderação extrema que seleciona e bane membros aleatórios (excluindo o dono e o bot).

### 1.2 Social & Gamificação
Engajamento da comunidade através de sistemas de progressão e ranking.
- **!xp:** Sistema de experiência que atribui pontos por interação. Os dados são persistidos de forma eficiente em formato JSON, permitindo a visualização de um ranking decrescente dos usuários mais ativos.

### 1.3 Mídia & IA
Integração com APIs externas para enriquecimento de conteúdo através de inteligência artificial.
- **!plot:** Busca metadados cinematográficos via OMDB API e utiliza o modelo Google Gemini para gerar um storytelling exclusivo e uma análise crítica baseada em notas agregadas (Rotten Tomatoes, IMDb).
- **!calabreso:** Comando de entretenimento que dispara mídias dinâmicas baseadas em memes virais.

### 1.4 Utilitários
Comandos de suporte e gerenciamento de interface.
- **!avatar:** Resgata a imagem de perfil de usuários em resoluções específicas (potências de 2).
- **!sair:** Comando administrativo para desligamento e saída formal do bot de uma guilda específica.

## 2. 🛠️ Arquitetura

O projeto adota uma arquitetura modular baseada no princípio de Responsabilidade Única (SRP), facilitando a manutenção e a escalabilidade do sistema.

- **Davibot.Consumer:** Atua como o roteador central de eventos. Ele normaliza as entradas (case-insensitive) e despacha as requisições para os módulos de domínio correspondentes.
- **Davibot.Commands.*:** Módulos especializados que contêm a lógica de negócio. Estão divididos em Moderation, Social, Utility e Media.
- **Davibot.Store:** Camada de persistência responsável pela serialização e desserialização de dados em arquivos locais, garantindo que informações como o XP dos usuários não sejam perdidas em reinicializações.
- **Davibot.Supervisor:** Gerencia a árvore de processos, garantindo que o bot se recupere automaticamente de falhas críticas.

## 3. ⚙️ Configuração

A configuração do ambiente é realizada através de um arquivo .env na raiz do projeto. O carregamento é gerenciado pelo runtime.exs para garantir segurança em tempo de execução.

**Variáveis obrigatórias:**
- **DISCORD_TOKEN:** Token de autenticação do bot no Portal do Desenvolvedor do Discord.
- **OMDB_TOKEN:** Chave de acesso à API de metadados de filmes.
- **GEMINI_API_KEY:** Chave de API para integração com os modelos de linguagem do Google.

## 4. 📦 Tecnologias

O stack tecnológico foi selecionado para priorizar performance e facilidade de integração com APIs REST e WebSockets.

- **Elixir:** Linguagem funcional executada na Erlang VM (BEAM).
- **Nostrum:** Biblioteca de interface para a API do Discord.
- **HTTPoison:** Cliente HTTP para requisições externas (OMDB).
- **Jason:** Biblioteca de alta performance para parsing de JSON.
- **GeminiEx:** Wrapper para integração com a IA generativa do Google.

## 5. 🏁 Como executar

Certifique-se de ter o Erlang/OTP e o Elixir instalados em seu ambiente antes de prosseguir.

1. Clone o repositório e acesse a pasta do projeto usando `cd davibot/davibot`.
2. Copie o arquivo *.env-template* usando o comando `cp ./.env-template ./.env`
3. No arquivo *.env* altere para usar as suas credenciais e poder usar o bot e o comando *!plot*
4. Instale as dependências necessárias:
`mix deps.get`
5. Compile o projeto e inicie o bot:
`mix run --no-halt`

## 🤖 Desenvolvimento Assistido por IA

Este projeto foi desenvolvido com o auxílio de Inteligência Artificial Generativa (IA), utilizando o modelo **Gemini 3.1 Pro**, **Qwen 3.5 Plus**, **GPT-5.1**, **Kimi K2.5**, **Gemini 3 Flash** e **Adapta ONE**. 

> Foi utilizado essa gama de modelos também com a finalidade de verificar qual entre eles possui um melhor conhecimento em Elixir e suas tecnologias como o Nostrum
> Exemplo: Os modelos **Qwen e Kimi** erravam as chamadas das funções da biblioteca Nostrum

A colaboração da IA no ciclo de desenvolvimento incluiu:
- **Refatoração de Arquitetura:** Migração de uma estrutura monolítica para um design modular e escalável.
- **Otimização de Código:** Implementação de padrões idiomáticos de Elixir (Pattern Matching, Guard Clauses e Pipes).
- **Documentação:** Geração de `@moduledoc`, `@doc` e parte desse arquivo README.
- **Resolução de Bugs:** Depuração de erros de runtime e validação de tipos baseada na documentação oficial da biblioteca `Nostrum`.

> [!NOTE]
> Embora a IA tenha atuado como um "Copiloto", toda a lógica de negócio, revisão técnica e decisões de design final foram validadas e supervisionadas pelo desenvolvedor humano, garantindo a integridade e segurança do bot.

