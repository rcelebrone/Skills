#!/bin/bash

# =========================================================================
# Configurações do Worker
# Repositório: Nome-Do-Seu-Projeto
# =========================================================================
REPO="nome-da-sua-org/Nome-Do-Seu-Projeto"
LABEL_PENDING="ai-task"
LABEL_PROCESSING="ai-processing"
LABEL_DONE="ai-done"
LOG_FILE=".agent-worker.log"

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR" || exit 1

echo "====================================================================="
echo ">>> Agent Worker Iniciado em modo contínuo."
echo ">>> Monitorando: $REPO"
echo ">>> Pressione [Ctrl+C] a qualquer momento para parar."
echo "====================================================================="

while true; do
    # 1. Busca a issue aberta mais antiga
    ISSUE_JSON=$(gh issue list --repo "$REPO" --state open --label "$LABEL_PENDING" --json number,title,body --limit 1)
    ISSUE_NUM=$(echo "$ISSUE_JSON" | jq -r '.[0].number // empty')

    if [ -z "$ISSUE_NUM" ]; then
        # Nenhuma issue encontrada. Dorme 5 minutos e tenta de novo silenciosamente.
        sleep 300
        continue
    fi

    ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.[0].title')
    ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.[0].body')
    BRANCH_NAME="feature/issue-$ISSUE_NUM"

    HEADLESS_PROMPT="$ISSUE_BODY

---
[INSTRUÇÃO DE SISTEMA INTERNO - SQUAD AUTÔNOMA]
REGRA MESTRE: Você só tem permissão para criar, deletar ou alterar arquivos DENTRO da pasta raiz deste projeto. É expressamente PROIBIDO modificar, ler ou excluir qualquer arquivo ou diretório fora do escopo deste repositório ou do sistema operacional subjacente.

Atue como um programador autônomo. Implemente a solução solicitada utilizando 
os agents e skills de acordo com instruções do arquivo .gemini/commands/manager.md. 
Não faça perguntas nem inclua introduções textuais.

O Desenvolvimento sempre irá começar por uma branch nova e será finalizado quando o 
Pull Request for aberto no github. 
Nota: Apenas gere, modifique e salve os arquivos localmente. O sistema empacotador 
(Worker) se encarregará de fazer o git add, commit, push e a abertura do PR automaticamente."

    echo ""
    echo ">>> [Passo 1/6] Issue identificada: #$ISSUE_NUM"
    echo ">>> [Passo 2/6] Processando: $ISSUE_TITLE"

    # Sinaliza processamento no GitHub
    gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PENDING" --add-label "$LABEL_PROCESSING" > /dev/null 2>&1

    # Prepara o Git garantindo ambiente limpo
    echo ">>> [Passo 3/6] Preparando Git (sincronizando e criando branch $BRANCH_NAME)..."
    git checkout main > /dev/null 2>&1 || { echo ">>> [ERRO] Falha ao dar checkout na main"; sleep 5; continue; }
    git fetch origin > /dev/null 2>&1
    git reset --hard origin/main > /dev/null 2>&1 || { echo ">>> [ERRO] Falha ao sincronizar com origin/main"; sleep 5; continue; }
    git clean -fd > /dev/null 2>&1

    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        git branch -D "$BRANCH_NAME" > /dev/null 2>&1
    fi

    git checkout -b "$BRANCH_NAME" > /dev/null 2>&1 || { echo ">>> [ERRO] Falha ao criar branch $BRANCH_NAME"; sleep 5; continue; }

    # ====================================================================================
    # EXECUÇÃO DO GEMINI COM GERAÇÃO DE LOG
    # ====================================================================================
    echo "--- Iniciando processamento da Issue #$ISSUE_NUM ---" > "$LOG_FILE"
    echo ">>> [Passo 4/6] Executando IA (Implementação e Validação Squad)... (Aguarde)"

    gemini --prompt "$HEADLESS_PROMPT" \
           --approval-mode yolo >> "$LOG_FILE" 2>&1 < /dev/null &
           
    GEMINI_PID=$!

    # Trava o script aqui aguardando o Gemini terminar silenciosamente
    wait $GEMINI_PID
    CLI_STATUS=$?

    echo ">>> [Passo 4/6] Execução da IA finalizada!"

    # Valida o resultado e prepara PR
    if [ $CLI_STATUS -eq 0 ]; then
        UNCOMMITTED_CHANGES=$(git status --porcelain)
        # Comparamos com origin/main para garantir que detectamos apenas mudanças reais vs remoto
        NEW_COMMITS=$(git log origin/main..HEAD --oneline 2>/dev/null)

        if [ -n "$UNCOMMITTED_CHANGES" ] || [ -n "$NEW_COMMITS" ]; then
            
            if [ -n "$UNCOMMITTED_CHANGES" ]; then
                echo ">>> [Passo 5/6] Alterações detectadas. Commitando e enviando branch..."
                git add -A > /dev/null 2>&1
                git commit -m "feat: resolve issue #$ISSUE_NUM - $ISSUE_TITLE" > /dev/null 2>&1
            else
                echo ">>> [Passo 5/6] Commits autônomos da IA detectados. Enviando branch..."
            fi
            
            # Tenta o push e verifica se teve sucesso
            if git push --force-with-lease -u origin "$BRANCH_NAME" 2> "$LOG_FILE.git_err"; then
                echo ">>> [Passo 6/6] Verificando e abrindo Pull Request..."
                
                # Garante que arquivos temporários não causem avisos de "uncommitted changes"
                rm -f "$LOG_FILE" "$LOG_FILE.git_err" "$LOG_FILE.pr_err"
                
                # Verifica se já existe um PR aberto para esta branch
                EXISTING_PR=$(gh pr list --repo "$REPO" --head "$BRANCH_NAME" --state open --json url --jq '.[0].url')
                
                if [ -n "$EXISTING_PR" ]; then
                    echo ">>> [AVISO] Pull Request já existe: $EXISTING_PR"
                    PR_URL=$EXISTING_PR
                    PR_STATUS=0
                else
                    PR_URL=$(gh pr create --repo "$REPO" \
                                         --base "main" \
                                         --head "$BRANCH_NAME" \
                                         --title "feat: $ISSUE_TITLE (Issue #$ISSUE_NUM)" \
                                         --body "Pull Request gerado automaticamente pela Squad IA.\n\nFixes #$ISSUE_NUM\n\n### Validação Interna\n- [x] Implementação concluída\n- [x] Arquitetura baseada em \`.gemini/commands/manager.md\`" 2> "$LOG_FILE.pr_err")
                    PR_STATUS=$?
                fi
                
                if [ $PR_STATUS -eq 0 ]; then
                    gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_DONE" > /dev/null 2>&1
                    gh issue close "$ISSUE_NUM" --repo "$REPO" > /dev/null 2>&1
                    echo ">>> [OK] Sucesso! PR processado: $PR_URL"
                else
                    # Caso especial: Se não há commits, não adianta tentar de novo
                    if grep -q "No commits between" "$LOG_FILE.pr_err"; then
                        echo ">>> [AVISO] O GitHub informou que não há commits novos para o PR (já integrados ou vazios)."
                        gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_DONE" > /dev/null 2>&1
                        gh issue close "$ISSUE_NUM" --repo "$REPO" > /dev/null 2>&1
                    else
                        echo ">>> [ERRO] Falha ao criar Pull Request no GitHub."
                        cat "$LOG_FILE.pr_err"
                        # Reverte label para pending para reprocessamento futuro apenas em erros reais
                        gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_PENDING" > /dev/null 2>&1
                    fi
                fi
            else
                echo ">>> [ERRO] Falha ao enviar branch para o remoto (git push)."
                cat "$LOG_FILE.git_err"
                gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_PENDING" > /dev/null 2>&1
            fi
        else
            gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_PENDING" > /dev/null 2>&1
            echo ">>> [AVISO] O LLM executou sem erros, mas NENHUM código foi alterado."
            echo ">>> Veja o motivo abaixo (Últimas linhas do log do Gemini):"
            echo "--------------------------------------------------------"
            tail -n 15 "$LOG_FILE"
            echo "--------------------------------------------------------"
            git checkout main > /dev/null 2>&1
        fi
    else
        gh issue edit "$ISSUE_NUM" --repo "$REPO" --remove-label "$LABEL_PROCESSING" --add-label "$LABEL_PENDING" > /dev/null 2>&1
        echo ">>> [ERRO] Falha na execução da IA (código $CLI_STATUS)."
        echo ">>> Veja o motivo do erro abaixo (Últimas linhas do log do Gemini):"
        echo "--------------------------------------------------------"
        tail -n 15 "$LOG_FILE"
        echo "--------------------------------------------------------"
        git checkout main > /dev/null 2>&1
    fi

    echo ">>> Ciclo finalizado. Retomando monitoramento em 5 segundos..."
    sleep 5
done
