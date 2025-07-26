Criei um sistema completo de desmanche de veículos para GTA V usando a framework VRP! O sistema inclui:

## 🚗 **Arquivos Principais:**

1. **server.lua** - Lógica do servidor com:
   - Sistema de cooldown
   - Verificação de policiais online
   - Cálculo de valores por classe de veículo
   - Geração de materiais aleatórios
   - Alertas para polícia

2. **client.lua** - Interface do cliente com:
   - Markers visuais 3D
   - Barra de progresso
   - Verificações de segurança
   - Interações com o jogador

3. **config.lua** - Configurações detalhadas:
   - Valores por classe de veículo
   - Lista de materiais obtidos
   - Veículos proibidos
   - Mensagens personalizáveis

4. **fxmanifest.lua** - Manifesto do resource

5. **README.md** - Documentação completa

## ⭐ **Características Principais:**

- **Sistema Realista**: Tempo de desmanche de 30 segundos
- **Valores Dinâmicos**: Carros super ($12k-$20k), sedans ($3k-$6k), etc.
- **Materiais Diversos**: Metal, plástico, borracha, vidro, tecido
- **Segurança**: Anti-cheat, cooldown de 5 minutos, verificação de distância
- **Sistema Policial**: Alertas automáticos com 75% de chance
- **Interface Visual**: Markers, blips, barra de progresso, textos 3D

## 🛠️ **Para Instalar:**

1. Crie uma pasta `vrp_desmanche` em `resources/[vrp]/`
2. Coloque todos os arquivos na pasta
3. Adicione `ensure vrp_desmanche` no server.cfg
4. Configure os itens no sistema de inventário do VRP
5. Ajuste as permissões conforme necessário

O sistema está pronto para uso e totalmente configurável! Você pode ajustar valores, localização, tempos e restrições no arquivo de configuração.