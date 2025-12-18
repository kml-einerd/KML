# Guia de Deploy para Google Cloud Run

Este guia ajudará você a implantar o **English Plan** no Google Cloud Run, um serviço "serverless" que roda containers de forma escalável e barata (frequentemente gratuita para baixo tráfego).

## Pré-requisitos

1.  Uma conta no Google Cloud Platform (GCP).
2.  `gcloud` CLI instalado na sua máquina (ou use o Google Cloud Shell no navegador).
3.  Docker instalado (se for construir localmente).

---

## Passo 1: Configurar o Google Cloud

1.  Acesse o [Console do GCP](https://console.cloud.google.com/).
2.  Crie um novo projeto (ex: `english-plan-prod`).
3.  Ative as APIs necessárias:
    *   Cloud Run API
    *   Artifact Registry API
    *   Cloud Build API

```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
```

---

## Passo 2: Preparar o Repositório de Imagens

Você precisa de um lugar para armazenar a imagem Docker do seu app.

1.  Crie um repositório no Artifact Registry:

```bash
gcloud artifacts repositories create english-plan-repo \
    --repository-format=docker \
    --location=us-central1 \
    --description="English Plan Docker Repository"
```

---

## Passo 3: Construir e Enviar o Container

Você pode usar o Cloud Build para construir a imagem diretamente na nuvem (sem precisar de Docker local pesado).

1.  Na pasta raiz do projeto (`english-plan`), execute:

```bash
gcloud builds submit --tag us-central1-docker.pkg.dev/SEU_PROJECT_ID/english-plan-repo/english-plan-web:v1 .
```

*Substitua `SEU_PROJECT_ID` pelo ID do seu projeto GCP.*

---

## Passo 4: Implantar no Cloud Run

Agora vamos colocar o container para rodar.

1.  Execute o comando de deploy:

```bash
gcloud run deploy english-plan-web \
    --image us-central1-docker.pkg.dev/SEU_PROJECT_ID/english-plan-repo/english-plan-web:v1 \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --port 80
```

*   `--allow-unauthenticated`: Permite que qualquer pessoa acesse o site (público).
*   `--port 80`: A porta que configuramos no Nginx (`Dockerfile` e `nginx.conf`).

---

## Passo 5: Configurar Variáveis de Ambiente (Supabase)

Para conectar ao banco de dados real, você precisa configurar as variáveis de ambiente no Cloud Run.

1.  Vá para o painel do Cloud Run no Console GCP.
2.  Clique no serviço `english-plan-web`.
3.  Clique em **Editar e implantar nova revisão**.
4.  Na aba **Variáveis e secrets**, adicione:
    *   `VITE_SUPABASE_URL`: (Sua URL do Supabase)
    *   `VITE_SUPABASE_ANON_KEY`: (Sua chave Anon do Supabase)
5.  Clique em **Implantar**.

---

## Atualizações Futuras

Para atualizar o site:
1.  Faça suas alterações no código.
2.  Rode o comando de Build (Passo 3) com uma nova tag (ex: `:v2`).
3.  Rode o comando de Deploy (Passo 4) com a nova imagem.

**Parabéns! Seu app "English Plan" está no ar! 🚀**
