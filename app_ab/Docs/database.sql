-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.ativos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  codigo text,
  descricao text,
  tipo_ativo text,
  emissor_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ativos_pkey PRIMARY KEY (id),
  CONSTRAINT ativos_emissor_id_fkey FOREIGN KEY (emissor_id) REFERENCES public.emissores(id)
);
CREATE TABLE public.audit_etl (
  id bigint NOT NULL DEFAULT nextval('audit_etl_id_seq'::regclass),
  run_at timestamp with time zone NOT NULL DEFAULT now(),
  run_by text DEFAULT CURRENT_USER,
  status text NOT NULL,
  rows_top_movers integer DEFAULT 0,
  rows_fresh_bets integer DEFAULT 0,
  notes text,
  duration_seconds double precision DEFAULT 0,
  attempts integer DEFAULT 1,
  error_message text,
  CONSTRAINT audit_etl_pkey PRIMARY KEY (id)
);
CREATE TABLE public.emissores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cnpj_cpf text UNIQUE,
  nome_emissor text,
  tipo_pessoa text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT emissores_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fresh_bets (
  id bigint NOT NULL DEFAULT nextval('fresh_bets_id_seq'::regclass),
  fundo_id uuid,
  ativo_id uuid,
  first_seen date NOT NULL,
  last_seen date NOT NULL,
  quantity numeric,
  value numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT fresh_bets_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fresh_bets_participantes (
  id bigint NOT NULL DEFAULT nextval('fresh_bets_participantes_id_seq'::regclass),
  fresh_bet_id bigint,
  participante_id uuid,
  quantidade numeric,
  valor numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT fresh_bets_participantes_pkey PRIMARY KEY (id),
  CONSTRAINT fresh_bets_participantes_fresh_bet_id_fkey FOREIGN KEY (fresh_bet_id) REFERENCES public.fresh_bets(id)
);
CREATE TABLE public.fundos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cnpj text NOT NULL UNIQUE,
  nome_fundo text,
  classe text,
  is_grande_fundo boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fundos_pkey PRIMARY KEY (id)
);
CREATE TABLE public.patrimonio_liquido (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fundo_id uuid NOT NULL,
  data_competencia date NOT NULL,
  valor_pl numeric,
  mes_referencia date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT patrimonio_liquido_pkey PRIMARY KEY (id),
  CONSTRAINT patrimonio_liquido_fundo_id_fkey FOREIGN KEY (fundo_id) REFERENCES public.fundos(id)
);
CREATE TABLE public.posicoes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fundo_id uuid NOT NULL,
  ativo_id uuid,
  data_competencia date NOT NULL,
  tipo_aplicacao text,
  qtd_posicao_final numeric,
  valor_mercado_final numeric,
  valor_custo_final numeric,
  percentual_carteira numeric,
  mes_referencia date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT posicoes_pkey PRIMARY KEY (id),
  CONSTRAINT posicoes_fundo_id_fkey FOREIGN KEY (fundo_id) REFERENCES public.fundos(id),
  CONSTRAINT posicoes_ativo_id_fkey FOREIGN KEY (ativo_id) REFERENCES public.ativos(id)
);
CREATE TABLE public.posicoes_confidenciais (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fundo_id uuid NOT NULL,
  data_competencia date NOT NULL,
  tipo_aplicacao text,
  valor_mercado numeric,
  mes_referencia date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT posicoes_confidenciais_pkey PRIMARY KEY (id),
  CONSTRAINT posicoes_confidenciais_fundo_id_fkey FOREIGN KEY (fundo_id) REFERENCES public.fundos(id)
);
CREATE TABLE public.posicoes_detalhes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  posicao_id uuid,
  detalhes jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT posicoes_detalhes_pkey PRIMARY KEY (id),
  CONSTRAINT posicoes_detalhes_posicao_id_fkey FOREIGN KEY (posicao_id) REFERENCES public.posicoes(id)
);
CREATE TABLE public.posicoes_exterior (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fundo_id uuid NOT NULL,
  data_competencia date NOT NULL,
  codigo_ativo text,
  descricao_ativo text,
  valor_mercado numeric,
  mes_referencia date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT posicoes_exterior_pkey PRIMARY KEY (id),
  CONSTRAINT posicoes_exterior_fundo_id_fkey FOREIGN KEY (fundo_id) REFERENCES public.fundos(id)
);
CREATE TABLE public.snapshots_posicoes (
  id bigint NOT NULL DEFAULT nextval('snapshots_posicoes_id_seq'::regclass),
  fundo_id uuid,
  ativo_id uuid,
  data_snapshot date NOT NULL,
  quantidade numeric,
  valor_mark_to_market numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT snapshots_posicoes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.top_movers (
  id bigint NOT NULL DEFAULT nextval('top_movers_id_seq'::regclass),
  fundo_id uuid,
  ativo_id uuid,
  data_snapshot date NOT NULL,
  pct_change numeric,
  change_absolute numeric,
  prev_quantity numeric,
  curr_quantity numeric,
  prev_value numeric,
  curr_value numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT top_movers_pkey PRIMARY KEY (id)
);