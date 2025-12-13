# Exemplos de Outputs - Análise de Ações

Exemplos visuais de como ficam os resultados das queries de análise.

---

## 1. Top 10 Ações Mais Compradas

```sql
SELECT * FROM v_ranking_compras_mes
WHERE ano = 2025 AND mes = 10 AND ranking_compra <= 10;
```

**Output:**
```
┌────────┬──────────────────┬────────────────┬───────────────────┬─────────────────────┬────────────────────────┬──────────────┐
│ ticker │   empresa_nome   │     setor      │ categoria_analise │ fundos_compradores  │ total_comprado_milhoes │ ranking_compra│
├────────┼──────────────────┼────────────────┼───────────────────┼─────────────────────┼────────────────────────┼──────────────┤
│ PETR4  │ Petrobras       │ Petróleo e Gás │ Blue Chip         │          45         │        R$ 120,5        │      1       │
│ VALE3  │ Vale            │ Mineração      │ Blue Chip         │          38         │        R$ 95,2         │      2       │
│ ITUB4  │ Itaú Unibanco   │ Bancos         │ Blue Chip         │          42         │        R$ 80,3         │      3       │
│ BBDC4  │ Bradesco        │ Bancos         │ Blue Chip         │          35         │        R$ 65,7         │      4       │
│ MGLU3  │ Magazine Luiza  │ Varejo         │ Growth            │          28         │        R$ 45,1         │      5       │
│ ABEV3  │ Ambev           │ Alimentos      │ Blue Chip         │          30         │        R$ 38,9         │      6       │
│ BBAS3  │ Banco do Brasil │ Bancos         │ Blue Chip         │          25         │        R$ 35,4         │      7       │
│ VAMO3  │ Vamos           │ Logística      │ Growth            │          18         │        R$ 28,7         │      8       │
│ LREN3  │ Lojas Renner    │ Varejo         │ Value             │          22         │        R$ 25,3         │      9       │
│ SANB11 │ Santander       │ Bancos         │ Blue Chip         │          20         │        R$ 22,1         │     10       │
└────────┴──────────────────┴────────────────┴───────────────────┴─────────────────────┴────────────────────────┴──────────────┘
```

**Interpretação:**
- PETR4 lidera com 45 fundos comprando R$ 120,5 milhões
- Forte concentração em Blue Chips (7 das 10)
- Bancos recebendo fluxo significativo (4 ações)

---

## 2. Fluxo Líquido por Ação

```sql
SELECT ticker, empresa_nome, setor, fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND tendencia_mercado IN ('FORTE COMPRA', 'FORTE VENDA')
ORDER BY ABS(fluxo_liquido) DESC LIMIT 10;
```

**Output:**
```
┌────────┬──────────────────┬────────────────┬───────────────────────┬──────────────────┐
│ ticker │   empresa_nome   │     setor      │ fluxo_liquido_milhoes │ tendencia_mercado│
├────────┼──────────────────┼────────────────┼───────────────────────┼──────────────────┤
│ PETR4  │ Petrobras       │ Petróleo e Gás │      +R$ 85,3         │ FORTE COMPRA     │
│ VALE3  │ Vale            │ Mineração      │      +R$ 72,1         │ FORTE COMPRA     │
│ ITUB4  │ Itaú Unibanco   │ Bancos         │      +R$ 45,8         │ FORTE COMPRA     │
│ MGLU3  │ Magazine Luiza  │ Varejo         │      -R$ 38,2         │ FORTE VENDA      │
│ BBDC4  │ Bradesco        │ Bancos         │      +R$ 35,6         │ FORTE COMPRA     │
│ ABEV3  │ Ambev           │ Alimentos      │      +R$ 28,4         │ FORTE COMPRA     │
│ VAMO3  │ Vamos           │ Logística      │      +R$ 22,1         │ FORTE COMPRA     │
│ LREN3  │ Lojas Renner    │ Varejo         │      -R$ 18,5         │ FORTE VENDA      │
│ BEEF3  │ Minerva         │ Alimentos      │      -R$ 12,3         │ FORTE VENDA      │
│ TASA4  │ Taurus          │ Defesa         │      +R$ 8,7          │ FORTE COMPRA     │
└────────┴──────────────────┴────────────────┴───────────────────────┴──────────────────┘
```

**Interpretação:**
- PETR4 e VALE3: Forte consenso de compra
- MGLU3: Forte saída de capital (possível realização de lucros)
- Small cap TASA4 com movimento positivo interessante

---

## 3. Concentração por Setor

```sql
SELECT setor, valor_investido_bilhoes, fluxo_liquido_milhoes,
       percentual_total_acoes, rentabilidade_media_pct
FROM v_concentracao_setor_acoes
WHERE ano = 2025 AND mes = 10
ORDER BY fluxo_liquido_mes DESC;
```

**Output:**
```
┌────────────────┬──────────────────────┬───────────────────────┬────────────────────┬─────────────────────┐
│     setor      │ investido_bilhoes    │ fluxo_liquido_milhoes │ % total_acoes      │ rentabilidade_pct   │
├────────────────┼──────────────────────┼───────────────────────┼────────────────────┼─────────────────────┤
│ Petróleo e Gás │     R$ 45,2          │      +R$ 125,3        │       28,5%        │      +12,3%         │
│ Mineração      │     R$ 32,8          │      +R$ 85,7         │       20,7%        │      +8,5%          │
│ Bancos         │     R$ 28,5          │      +R$ 72,4         │       18,0%        │      +5,2%          │
│ Alimentos      │     R$ 15,3          │      +R$ 35,8         │        9,7%        │      +6,8%          │
│ Logística      │     R$ 12,1          │      +R$ 28,2         │        7,6%        │      +15,2%         │
│ Varejo         │     R$ 18,7          │      -R$ 42,5         │       11,8%        │      -3,5%          │
│ Defesa         │     R$ 2,3           │      +R$ 8,9          │        1,5%        │      +22,1%         │
│ Outros         │     R$ 3,5           │      -R$ 5,2          │        2,2%        │      +1,2%          │
└────────────────┴──────────────────────┴───────────────────────┴────────────────────┴─────────────────────┘
```

**Interpretação:**
- Rotação: Saída de Varejo (-R$ 42,5 mi) → Entrada em Petróleo e Gás (+R$ 125,3 mi)
- Logística e Defesa com alta rentabilidade (15,2% e 22,1%)
- Bancos estáveis com fluxo positivo moderado

---

## 4. Quem Investe em PETR4?

```sql
SELECT nome_grupo, nome_fundo, posicao_milhoes,
       tipo_movimentacao, rentabilidade_pct
FROM v_movimentacoes_acoes
WHERE ticker = 'PETR4' AND ano = 2025 AND mes = 10
ORDER BY valor_mercado_posicao DESC LIMIT 10;
```

**Output:**
```
┌──────────────────┬──────────────────────────────────┬──────────────────┬───────────────────┬──────────────────┐
│   nome_grupo     │          nome_fundo              │ posicao_milhoes  │ tipo_movimentacao │ rentabilidade_%  │
├──────────────────┼──────────────────────────────────┼──────────────────┼───────────────────┼──────────────────┤
│ BTG Pactual      │ BTG Pactual Ações FIA            │   R$ 450,5       │ COMPRA            │    +15,2%        │
│ Itaú Unibanco    │ Itaú Premium Ações FIA           │   R$ 385,2       │ COMPRA            │    +14,8%        │
│ XP Investimentos │ XP Top Ações FIC FIA             │   R$ 320,8       │ SEM MOVIMENTAÇÃO  │    +13,5%        │
│ Bradesco         │ Bradesco FIA Fundamental         │   R$ 285,3       │ VENDA             │    +12,1%        │
│ BTG Pactual      │ BTG Dividendos FIA               │   R$ 245,7       │ COMPRA            │    +16,3%        │
│ Caixa            │ Caixa Crescimento Ações FIA      │   R$ 210,4       │ COMPRA            │    +11,9%        │
│ XP Investimentos │ XP Valor FIA                     │   R$ 195,8       │ COMPRA            │    +14,2%        │
│ Santander        │ Santander Select Ações FIA       │   R$ 175,3       │ SEM MOVIMENTAÇÃO  │    +12,7%        │
│ Itaú Unibanco    │ Itaú Carteira Livre Ações FIA    │   R$ 165,2       │ VENDA             │    +10,8%        │
│ BTG Pactual      │ BTG Pactual Small Caps FIA       │   R$ 142,7       │ COMPRA            │    +18,5%        │
└──────────────────┴──────────────────────────────────┴──────────────────┴───────────────────┴──────────────────┘
```

**Interpretação:**
- BTG Pactual dominante com 3 fundos no top 10
- Maioria comprando (sinal positivo)
- Rentabilidade consistente entre 10-18%
- Bradesco e Itaú reduzindo posição (possível realização)

---

## 5. Carteira Sugerida (Compra + Dividendos)

```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, dividend_yield_medio,
       fundos_compradores
FROM v_fluxo_liquido_acoes f
JOIN v_analise_dividendos d USING (ticker, ano, mes)
WHERE f.ano = 2025 AND f.mes = 10
  AND tendencia_mercado IN ('FORTE COMPRA', 'COMPRA MODERADA')
  AND dividend_yield_medio >= 4.0
ORDER BY fluxo_liquido DESC LIMIT 10;
```

**Output:**
```
┌────────┬──────────────────┬────────────────┬───────────────────────┬──────────────┬────────────────────┐
│ ticker │   empresa_nome   │     setor      │ fluxo_liquido_milhoes │  DY médio %  │ fundos_compradores │
├────────┼──────────────────┼────────────────┼───────────────────────┼──────────────┼────────────────────┤
│ PETR4  │ Petrobras       │ Petróleo e Gás │      +R$ 85,3         │    14,5%     │        45          │
│ VALE3  │ Vale            │ Mineração      │      +R$ 72,1         │    10,3%     │        38          │
│ BBAS3  │ Banco do Brasil │ Bancos         │      +R$ 35,4         │     7,5%     │        25          │
│ BBDC4  │ Bradesco        │ Bancos         │      +R$ 35,6         │     6,8%     │        35          │
│ ITUB4  │ Itaú Unibanco   │ Bancos         │      +R$ 45,8         │     5,2%     │        42          │
│ SANB11 │ Santander       │ Bancos         │      +R$ 22,1         │     6,2%     │        20          │
│ ABEV3  │ Ambev           │ Alimentos      │      +R$ 28,4         │     4,8%     │        30          │
│ LREN3  │ Lojas Renner    │ Varejo         │      +R$ 8,2          │     4,2%     │        12          │
└────────┴──────────────────┴────────────────┴───────────────────────┴──────────────┴────────────────────┘
```

**Estratégia:**
- **PETR4**: Melhor combinação (forte compra + DY 14,5%)
- **Bancos**: Boas opções para renda (DY 5-7%) com fluxo positivo
- **VALE3**: Boa opção para crescimento + dividendos

---

## 6. Top Posições por Grupo Econômico

```sql
SELECT nome_grupo, ticker, empresa_nome, setor,
       investido_milhoes, ranking_grupo
FROM v_top_posicoes_grupos
WHERE ano = 2025 AND mes = 10
  AND nome_grupo IN ('BTG Pactual', 'Itaú Unibanco', 'XP Investimentos')
  AND ranking_grupo <= 5
ORDER BY nome_grupo, ranking_grupo;
```

**Output:**
```
┌──────────────────┬────────┬──────────────────┬────────────────┬───────────────────┬──────────────┐
│   nome_grupo     │ ticker │   empresa_nome   │     setor      │ investido_milhoes │ ranking_grupo│
├──────────────────┼────────┼──────────────────┼────────────────┼───────────────────┼──────────────┤
│ BTG Pactual      │ PETR4  │ Petrobras       │ Petróleo e Gás │    R$ 1.250,5     │      1       │
│ BTG Pactual      │ VALE3  │ Vale            │ Mineração      │    R$ 1.080,2     │      2       │
│ BTG Pactual      │ ITUB4  │ Itaú Unibanco   │ Bancos         │    R$ 890,7       │      3       │
│ BTG Pactual      │ BBDC4  │ Bradesco        │ Bancos         │    R$ 750,3       │      4       │
│ BTG Pactual      │ ABEV3  │ Ambev           │ Alimentos      │    R$ 680,5       │      5       │
│                  │        │                  │                │                   │              │
│ Itaú Unibanco    │ VALE3  │ Vale            │ Mineração      │    R$ 980,5       │      1       │
│ Itaú Unibanco    │ PETR4  │ Petrobras       │ Petróleo e Gás │    R$ 850,3       │      2       │
│ Itaú Unibanco    │ BBDC4  │ Bradesco        │ Bancos         │    R$ 720,8       │      3       │
│ Itaú Unibanco    │ ABEV3  │ Ambev           │ Alimentos      │    R$ 580,2       │      4       │
│ Itaú Unibanco    │ MGLU3  │ Magazine Luiza  │ Varejo         │    R$ 450,7       │      5       │
│                  │        │                  │                │                   │              │
│ XP Investimentos │ PETR4  │ Petrobras       │ Petróleo e Gás │    R$ 720,5       │      1       │
│ XP Investimentos │ ITUB4  │ Itaú Unibanco   │ Bancos         │    R$ 650,2       │      2       │
│ XP Investimentos │ VALE3  │ Vale            │ Mineração      │    R$ 580,8       │      3       │
│ XP Investimentos │ VAMO3  │ Vamos           │ Logística      │    R$ 380,5       │      4       │
│ XP Investimentos │ MGLU3  │ Magazine Luiza  │ Varejo         │    R$ 320,3       │      5       │
└──────────────────┴────────┴──────────────────┴────────────────┴───────────────────┴──────────────┘
```

**Análise:**
- **Consenso**: PETR4, VALE3 e bancos em todos os grupos
- **Diferença**: XP tem VAMO3 no top 5 (aposta em logística)
- **Valor total**: BTG investe mais capital (maior volume)

---

## 7. Evolução Temporal (3 meses)

```sql
SELECT mes_nome, ticker, empresa_nome,
       fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes IN (8, 9, 10)
  AND ticker IN ('PETR4', 'VALE3', 'MGLU3')
ORDER BY ticker, mes;
```

**Output:**
```
┌───────────┬────────┬──────────────────┬───────────────────────┬──────────────────┐
│ mes_nome  │ ticker │   empresa_nome   │ fluxo_liquido_milhoes │ tendencia_mercado│
├───────────┼────────┼──────────────────┼───────────────────────┼──────────────────┤
│ Agosto    │ PETR4  │ Petrobras       │      +R$ 45,2         │ FORTE COMPRA     │
│ Setembro  │ PETR4  │ Petrobras       │      +R$ 68,5         │ FORTE COMPRA     │
│ Outubro   │ PETR4  │ Petrobras       │      +R$ 85,3         │ FORTE COMPRA     │
│           │        │                  │                       │                  │
│ Agosto    │ VALE3  │ Vale            │      +R$ 28,7         │ COMPRA MODERADA  │
│ Setembro  │ VALE3  │ Vale            │      +R$ 52,3         │ FORTE COMPRA     │
│ Outubro   │ VALE3  │ Vale            │      +R$ 72,1         │ FORTE COMPRA     │
│           │        │                  │                       │                  │
│ Agosto    │ MGLU3  │ Magazine Luiza  │      +R$ 15,3         │ COMPRA MODERADA  │
│ Setembro  │ MGLU3  │ Magazine Luiza  │      -R$ 8,5          │ VENDA MODERADA   │
│ Outubro   │ MGLU3  │ Magazine Luiza  │      -R$ 38,2         │ FORTE VENDA      │
└───────────┴────────┴──────────────────┴───────────────────────┴──────────────────┘
```

**Interpretação:**
- **PETR4**: Tendência consistente de compra (3 meses crescentes)
- **VALE3**: Aceleração de compras (de moderada para forte)
- **MGLU3**: REVERSÃO! De compra → venda forte (sinal de alerta)

---

## Conclusão

Com estas visualizações você pode:

1. **Identificar oportunidades**: Ações com forte fluxo de compra
2. **Evitar armadilhas**: Ações com forte fluxo de venda
3. **Diversificar**: Entender concentração setorial
4. **Copiar estratégias**: Ver o que grandes grupos fazem
5. **Confirmar tendências**: Análise temporal de 3+ meses
6. **Gerar renda**: Combinar dividendos + fluxo positivo

**Principais Insights:**
- Blue Chips dominam (PETR4, VALE3, bancos)
- Setores cíclicos recebendo fluxo (Petróleo, Mineração)
- Varejo em rotação (saída de capital)
- Small Caps seletivas (VAMO3, TASA4) com bom fluxo
- Dividendos: PETR4 melhor opção (DY 14,5% + forte compra)
