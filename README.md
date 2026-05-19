# DotAgents — Multi-Agent Management Boilerplate

Template agnóstico para instalar uma squad multi-agente (PO, Architect, Tech Lead, Developer, QA, Security, Ops) em qualquer projeto que use ferramentas de gerenciamento de agentes.

A squad é regida por um **manager central**, tem **personas** com responsabilidades claras, **skills** reutilizáveis e uma **memória viva** específica do projeto.

---

## 🚀 Instalação

Primeiro, clone este repositório como `DotAgents/` dentro do seu projeto:

```bash
git clone https://github.com/rodrigo-celebrone/DotAgents.git DotAgents
```

Agora, siga as instruções de acordo com a ferramenta que você utiliza:

### ♊ Gemini-CLI
#### 1. Execute o instalador
```bash
./DotAgents/instalador-gemini-cli.sh
```
```bash
gemini
```
#### 2. 🤖 Prompt para o LLM
> "Siga as instruções do `commands/bootstrap.md` para instalar a squad no gemini-cli"

---

### 🚀 Antigravity
#### 1. Execute o instalador
```bash
./DotAgents/instalador-antigravity.sh
```
#### 2. 🤖 Prompt para o LLM
> "Siga as instruções do `commands/bootstrap.md` para instalar a squad no antigravity"

---

### ❄️ Claude Code
#### 1. Execute o instalador
```bash
./DotAgents/instalador-claude.sh
```
```bash
claude
```
#### 2. 🤖 Prompt para o LLM
> "Siga as instruções do `commands/bootstrap.md` para instalar a squad no claude-code"

---

### 🖱️ Cursor AI
#### 1. Execute o instalador
```bash
./DotAgents/instalador-cursor.sh
```
#### 2. 🤖 Prompt para o LLM
> "Siga as instruções do `commands/bootstrap.md` para instalar a squad no cursor"

---

## 🏗️ A Squad

| Persona | Responsabilidade |
|---|---|
| 🎯 **Product Owner** | Refina regras de negócio, define DoD. |
| 🏛️ **Architect** | Integridade sistêmica, ADRs. |
| 👑 **Tech Lead** | Triagem técnica, criação de tasks, coordenação ágil. |
| 💻 **Developer** | Implementação Clean Code + TDD. |
| 🧪 **QA Specialist** | Validação funcional, RCA de bugs. |
| 🔒 **Security Specialist** | Threat modeling, AppSec audit. |
| 🚀 **Ops** | Ciclo de entrega local, deploy. |

---

## 🤖 Worker Autônomo (Exclusivo Gemini CLI)

O DotAgents inclui um recurso de **Agent Worker** (localizado em `.worker/`) que permite transformar seu repositório em um ambiente de desenvolvimento autônomo. 

**Nota:** Este recurso é projetado especificamente para uso com o **Gemini CLI**. Usuários do Cursor, Antigravity ou Claude Code não conseguirão utilizar este worker, pois ele depende da interface de linha de comando do Gemini para a execução das tarefas.

O worker monitora Issues com a label `ai-task` e utiliza o Gemini CLI para implementar soluções, abrir Pull Requests e fechar as Issues automaticamente.

Para saber como configurar e utilizar o worker em seus projetos, consulte o [Guia do Worker](.worker/README.md).

---

## 📁 Estrutura

- `agents/`: Definições das personas.
- `skills/`: Habilidades especializadas.
- `commands/`: Workflows e gerenciamento.
- `memorys/`: Memória viva (Business, Architecture, Guidelines).

---

## 📄 Licença

Consulte o arquivo [`license.md`](license.md) para detalhes sobre os termos de uso.
