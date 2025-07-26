# Sistema de Desmanche de Veículos

Este documento detalha o funcionamento e a configuração do sistema de desmanche de veículos, integrado ao `[FLUXO-EMPREGOS]`.

## Visão Geral

O script permite que jogadores com as permissões corretas desmanchem veículos em locais pré-definidos. O processo é dividido em etapas, desde a identificação do veículo até a venda final do chassi, com pagamentos baseados em uma porcentagem do valor do veículo definido no script `nation_garages`.

---

## 1. Configuração Principal (`[FLUXO-EMPREGOS]/fluxoEmpregos/config/desmanche.lua`)

Este é o arquivo central para configurar todos os locais de desmanche. Cada local é um objeto dentro da tabela `cfg.desmanche`.

### Adicionando um Novo Local de Desmanche

Para adicionar um novo local, copie e cole um dos blocos existentes e altere as coordenadas e configurações.

```lua
cfg.desmanche = {
    {
        -- Desmanche Geral
        iniciar     = { -2544.27, 2540.8, 7.95 },      -- Onde o jogador inicia o processo (blip vermelho)
        desmanchar  = { -2547.22, 2538.59, 7.42 },     -- Posição para onde o veículo é movido para ser desmanchado
        ferramentas = { -2541.9, 2539.99, 7.95 },      -- Onde o jogador pega as ferramentas (blip vermelho)
        computador  = { -2544.55, 2538.78, 7.42, 336.03 }, -- Onde o jogador vende o chassi (laptop, o 4º valor é o heading/rotação)
        server = {
            restrito    = true, -- 'true' se o local exige permissão, 'false' se for aberto a todos
            permissions = { "desmanche.permissao" }, -- Lista de permissões VRP necessárias se restrito = true
            itens       = { {'chave', 1} } -- Lista de itens necessários para iniciar. Formato: { 'nome_do_item', quantidade }
        }
    },
    -- Adicione outros locais aqui
}
```

### Detalhes das Coordenadas:
-   `iniciar`: Coordenada do marcador onde o jogador pressiona [E] para identificar o veículo.
-   `desmanchar`: Posição para a qual o veículo é teleportado e congelado durante o processo.
-   `ferramentas`: Coordenada do marcador para pegar as ferramentas necessárias.
-   `computador`: Coordenada do laptop onde o chassi é vendido. O quarto valor opcional (`h`) define a rotação do objeto.

---

## 2. Fluxo do Jogador (Como Usar)

O processo para o jogador é linear e guiado por notificações e marcadores.

1.  **Iniciar o Desmanche:**
    -   Leve um veículo até a área de desmanche.
    -   Aproxime-se do marcador vermelho (`iniciar`) e pressione **[E]**.
    -   O sistema irá verificar se você tem a permissão e os itens necessários.

2.  **Pegar as Ferramentas:**
    -   Após o veículo ser identificado e movido, vá até o marcador de ferramentas e pressione **[E]**.
    -   Uma barra de progresso aparecerá.

3.  **Desmanchar as Peças:**
    -   Aproxime-se dos marcadores laranja que aparecem sobre as peças do veículo (portas, rodas, etc.).
    -   Pressione **[E]** em cada marcador para remover a peça. O sistema aplicará dano visual ao veículo.

4.  **Vender o Chassi:**
    -   Após remover todas as peças, vá até o laptop (marcador verde) e pressione **[E]**.
    -   Após uma barra de progresso, o chassi será vendido, o veículo será deletado e você receberá o pagamento.

5.  **Cancelar o Processo:**
    -   A qualquer momento, o jogador pode pressionar **F7** para cancelar o desmanche. Isso irá resetar o estado e liberar o veículo.

---

## 3. Integração e Pagamento

O valor pago pelo desmanche é diretamente ligado ao script `nation_garages`.

-   **Cálculo do Valor:** O pagamento é uma porcentagem do valor do veículo definido em `nation_garages/config.lua`.
-   **Alterando a Porcentagem:** Para alterar a porcentagem do pagamento, você deve editar o arquivo `nation_garages/server.lua`. Procure pelo evento `desmancheVehicles2` para encontrar a lógica de cálculo (atualmente definido como 30%).

---

## 4. Webhook do Discord

O script pode enviar um log para um canal do Discord toda vez que um veículo é desmanchado com sucesso.

-   **Configuração:** Abra o arquivo `[FLUXO-EMPREGOS]/fluxoEmpregos/ignore/fluxo_desmanche/client/client.lua`.
-   **Variável:** Insira o link da sua webhook na variável `desmanchelog` no topo do arquivo.

```lua
local desmanchelog = "https://discord.com/api/webhooks/..."
```

---

## 5. Dependências

-   **vrp:** Essencial para o funcionamento do framework.
-   **nation_garages:** Necessário para o sistema de preços dos veículos.
