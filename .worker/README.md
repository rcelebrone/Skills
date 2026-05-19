# DotAgents Worker Resource (Gemini CLI Only)

> [!IMPORTANT]
> **Compatibilidade:** Este worker foi desenvolvido exclusivamente para o **Gemini CLI**. Ele não é compatível com Cursor, Antigravity, Claude Code ou outros agentes de IA.

Este diretório contém os recursos necessários para rodar um **Agent Worker** autônomo. O worker monitora Issues em um repositório GitHub e utiliza o Gemini CLI para implementar soluções automaticamente.

## Recursos Incluídos

- `agent-worker.sh`: Script principal que roda dentro do container.
- `Dockerfile.worker`: Definição da imagem Docker do worker.
- `docker-compose.worker.yml`: Configuração do Docker Compose.
- `run-worker.sh`: Script auxiliar para iniciar o worker localmente.
- `.env.example`: Exemplo de arquivo de configuração.

## Como usar em seu projeto

1. **Copie a pasta `.worker`** para a raiz do seu projeto.
2. **Crie o arquivo `.env`**:
   ```bash
   cp .worker/.env.example .worker/.env
   ```
3. **Configure o repositório**:
   Edite `.worker/.env` e altere a variável `REPO` para o seu `usuario/repositório`.
4. **Certifique-se de estar logado**:
   O worker utiliza as credenciais do `gh` e `gemini` do seu host.
5. **Inicie o worker**:
   ```bash
   ./.worker/run-worker.sh
   ```

## Pré-requisitos

- Docker e Docker Compose instalados.
- [GitHub CLI (gh)](https://cli.github.com/) instalado e logado.
- [Gemini CLI](https://github.com/google/gemini-cli) instalado e configurado.

## Funcionamento

O worker busca Issues com a label `ai-task`. Ao encontrar uma:
1. Altera a label para `ai-processing`.
2. Cria uma branch local.
3. Executa o Gemini CLI com as instruções da Issue.
4. Se houver alterações, faz o commit e envia para o GitHub.
5. Abre um Pull Request e altera a label para `ai-done`.
