# Axios

**Seu planejamento financeiro, de forma inteligente.**

O Axios é um aplicativo acadêmico de planejamento financeiro desenvolvido em
Flutter. Ele transforma dados financeiros em uma visão clara de renda, gastos,
saldo e metas, ajudando o usuário a organizar o orçamento e construir planos
financeiros realistas.

## Status — Checkpoint 5

O CP5 entrega um protótipo funcional para Web e Android, com cinco telas,
navegação completa, cálculos consistentes e integração Firebase:

- cadastro, login, restauração de sessão e logout por e-mail e senha;
- dashboard com renda, gastos, saldo, gráfico por categoria e meta em destaque;
- transações simuladas com busca e filtros;
- metas com progresso e contribuição mensal calculados;
- persistência das metas no Cloud Firestore por usuário;
- assistente demonstrativo com respostas determinísticas;
- navegação inferior com preservação do estado das abas;
- estados de carregamento, erro e lista vazia.

O cadastro e a persistência de metas foram validados manualmente no projeto
Firebase pela execução Web. A execução em Android está configurada, mas ainda não
foi aprovada em dispositivo físico ou emulador.

> **Escopo do CP5:** transações, resumo financeiro e respostas do assistente usam
> dados simulados. Pluggy Sandbox e IA generativa permanecem planejados para uma
> etapa futura e não são apresentados como integrações concluídas.

## Capturas de tela — Checkpoint 5

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/screenshots/01-login.png" width="240" alt="Tela de login do Axios"><br>
      <sub><strong>Login</strong> — acesso com e-mail e senha</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/02-cadastro.png" width="240" alt="Tela de cadastro do Axios"><br>
      <sub><strong>Cadastro</strong> — criação de uma nova conta</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/03-dashboard.png" width="240" alt="Dashboard financeiro do Axios"><br>
      <sub><strong>Dashboard</strong> — resumo financeiro e meta atual</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="docs/screenshots/04-transacoes.png" width="240" alt="Tela de transações do Axios"><br>
      <sub><strong>Transações</strong> — busca, filtros e movimentações</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/05-metas.png" width="240" alt="Tela de metas do Axios"><br>
      <sub><strong>Metas</strong> — progresso e planejamento mensal</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/screenshots/06-assistente.png" width="240" alt="Assistente demonstrativo do Axios"><br>
      <sub><strong>Assistente</strong> — respostas financeiras simuladas</sub>
    </td>
  </tr>
  <tr>
    <td align="center" colspan="3">
      <img src="docs/screenshots/07-nova-meta.png" width="240" alt="Formulário de nova meta do Axios"><br>
      <sub><strong>Nova meta</strong> — formulário de criação e planejamento</sub>
    </td>
  </tr>
</table>

## Funcionalidades implementadas

### Autenticação

- Firebase Authentication com e-mail e senha.
- Validação dos formulários e mensagens de erro compreensíveis.
- Indicadores de carregamento durante cadastro e login.
- Sessão restaurada pelo Firebase ao reabrir o aplicativo.
- Logout disponível no fluxo autenticado.
- Falha de inicialização do Firebase apresentada com opção de tentar novamente.

### Dashboard e dados financeiros

- Renda mensal de referência: R$ 3.000,00.
- Gastos mensais de referência: R$ 2.150,00.
- Saldo estimado calculado: R$ 850,00.
- Gráfico calculado a partir das mesmas categorias das transações.
- Resumo da meta atual.

### Transações

- Lista rolável de receitas e despesas simuladas.
- Busca por descrição.
- Filtros Todas, Receitas e Despesas.
- Valores diferenciados por natureza da movimentação.
- Estado vazio para filtros sem resultados.

### Metas

- Metas associadas ao UID autenticado em `users/{uid}/goals`.
- Criação de meta por formulário.
- Progresso, saldo restante e contribuição mensal calculados.
- Persistência e restauração pelo Cloud Firestore.
- Metas de exemplo inseridas somente quando a coleção do usuário está vazia.

Na meta Viagem, por exemplo, os R$ 1.500,00 acumulados são descontados do
objetivo de R$ 6.000,00. Restam R$ 4.500,00 e, guardando R$ 500,00 por mês, o
prazo calculado é de 9 meses.

### Assistente Axios

- Interface de conversa com balões separados.
- Campo de mensagem e envio funcional.
- Rolagem automática.
- Respostas demonstrativas determinísticas, coerentes com os cálculos do app.
- Identificação explícita de que não há IA externa neste checkpoint.

## Tecnologias utilizadas

| Tecnologia | Uso no CP5 |
| --- | --- |
| Flutter e Dart | Interface, navegação, estado e regras de cálculo |
| Firebase Core | Inicialização do projeto Firebase |
| Firebase Authentication | Cadastro, sessão, login e logout |
| Cloud Firestore | Persistência das metas por usuário |
| `ChangeNotifier` | Estado simples da aplicação |
| `flutter_svg` | Logo vetorial local |
| `intl` | Formatação de moeda e datas em português |
| Inter e Manrope | Tipografia local, sem download em execução |

## Como executar

Pré-requisitos:

- Flutter compatível com Dart `^3.13.3`;
- Microsoft Edge para execução Web ou ambiente Android configurado;
- acesso ao projeto Firebase configurado no repositório.

Na raiz do projeto:

```powershell
flutter pub get
flutter devices
flutter run -d edge
```

Para Android:

```powershell
flutter devices
flutter run -d <id-do-dispositivo>
```

A configuração Android existe, mas o CP5 ainda precisa de QA em aparelho físico
ou emulador antes de ser considerado validado nessa plataforma.

### Modo demonstração

A execução normal sempre usa Firebase real. O modo em memória só é ativado de
forma explícita para testes e apresentações sem dados externos:

```powershell
flutter run -d edge --dart-define=AXIOS_DEMO_MODE=true
```

Nesse modo, a tela de login informa que autenticação e metas são demonstrativas.
Uma falha do Firebase em execução normal não ativa esse modo automaticamente.

## Configuração do Firebase

O aplicativo está associado ao projeto `axios-finance` para Android e Web. O
arquivo gerado pelo FlutterFire CLI, `lib/firebase_options.dart`, é carregado com
`DefaultFirebaseOptions.currentPlatform`.

Para reproduzir a configuração em outro ambiente:

1. Selecione ou crie o projeto no Firebase Console.
2. Habilite **Authentication > Sign-in method > Email/Password**.
3. Crie o banco Cloud Firestore.
4. Execute `flutterfire configure` e selecione Android e Web.
5. Confira `lib/firebase_options.dart` e `android/app/google-services.json`.
6. Publique as regras de `firestore.rules` no projeto correto.

As regras incluídas no repositório limitam o acesso ao usuário autenticado:

```text
users/{uid}/goals/{goalId}
```

Cada operação exige que `request.auth.uid` corresponda ao `uid` do caminho. O
aplicativo não contém service accounts, chaves administrativas ou senhas.

## Arquitetura

```text
lib/
  main.dart                    # Entrada e seleção explícita do modo demo
  bootstrap_app.dart           # Inicialização, erro seguro e nova tentativa
  app.dart                     # MaterialApp e gate de autenticação
  app_dependencies.dart        # Injeção simples dos repositórios
  core/
    theme/                     # Cores, tipografia e tema
    utils/                     # Formatação monetária e de datas
  data/                        # Fonte central de dados simulados
  models/                      # Usuário, transação, resumo, meta e mensagem
  repositories/               # Firebase, Firestore e implementações em memória
  services/                    # Inicialização segura do Firebase
  state/                       # AppController com ChangeNotifier
  screens/                     # Autenticação, shell e telas principais
  widgets/                     # Componentes visuais reutilizáveis
test/                          # Testes unitários e de widgets
docs/screenshots/              # Documentação visual do CP5
firestore.rules                # Isolamento por UID autenticado
```

### Decisões técnicas do CP4 ao CP5

- O Design System criado no CP4 foi preservado e transformado em tema Flutter.
- A aplicação usa componentes nativos e `ChangeNotifier`, evitando complexidade
  desnecessária no protótipo.
- Repositórios isolam Firebase das telas e permitem testes sem serviços externos.
- Dados financeiros simulados são centralizados para manter Dashboard,
  Transações, Metas e Assistente consistentes.
- O shell usa `IndexedStack`, preservando cada aba sem empilhar rotas repetidas.
- Layouts usam `SafeArea`, rolagem e limites de largura para funcionar em telas
  móveis e Web.
- A aplicação falha de forma explícita se o Firebase não inicializar; não há
  fallback silencioso para autenticação fictícia.

## Testes e verificações

Comandos de qualidade:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

Na validação mais recente do CP5:

- `flutter analyze`: nenhuma ocorrência;
- `flutter test`: 16 testes aprovados;
- `flutter build web`: concluído com sucesso;
- inicialização Web no Edge: concluída;
- credencial inválida: rejeitada pelo Firebase Authentication;
- cadastro e persistência de meta: validados manualmente no Firebase;
- execução Android: ainda não validada.

Os testes cobrem cálculos financeiros, progresso das metas, filtros de
transações, navegação, validação de formulário, seleção de dependências, erros de
autenticação e nova tentativa após falha de inicialização. Eles usam repositórios
injetados e não criam usuários ou documentos remotos.

## Limitações conhecidas

- As transações ainda não vêm do Pluggy Sandbox.
- O assistente não usa IA generativa ou outro serviço externo.
- Não há sincronização bancária, edição avançada de transações ou notificações.
- A execução Android precisa de validação em emulador e aparelho físico.

## Próximos passos — CP6

1. Validar a experiência completa em Android e gerar o APK final.
2. Integrar o Pluggy Sandbox e substituir as transações simuladas.
3. Evoluir o assistente para IA real com limites, transparência e segurança.
4. Adicionar edição e exclusão de metas com testes de persistência.
5. Ampliar testes de integração e automação de release.
6. Avaliar gráficos históricos, notificações e acessibilidade avançada.

## Identidade visual

| Cor | Código | Uso |
| --- | --- | --- |
| Background | `#FAF8F2` | Fundo principal |
| Axios Gold | `#E6B800` | Ações e destaques |
| Gold Soft | `#F4E7B7` | Superfícies de destaque |
| Graphite | `#1F2937` | Títulos e textos principais |
| Gray | `#6B7280` | Textos secundários |
| Surface | `#FFFFFF` | Cartões e campos |
| Border | `#E5E7EB` | Contornos e divisores |
| Success | `#16A34A` | Receitas e estados positivos |
| Danger | `#DC2626` | Despesas e erros |

Manrope é usada em títulos, marca e números financeiros; Inter é usada em textos,
formulários, botões e navegação. A logo preserva o “A” geométrico dourado e
grafite definido no Figma.

### Nome e tom de voz

Axios é inspirado em uma palavra de origem grega associada a valor, mérito e
importância. A marca busca ser clara, inteligente, acessível e objetiva, sem
julgar os hábitos financeiros do usuário.

## Equipe

- Amom Ianaguivara — RM 565718
- Fernando Antônio — RM 562549
- Gabriel Ramos Moreira — RM 564074
- Vinicius Mello Siqueira — RM 565257
- Victor Chen — RM 565363

## Histórico acadêmico — Checkpoint 4

O CP4 definiu a proposta do produto, a identidade visual, o público e o protótipo
de interface no Figma. Naquele checkpoint, o projeto Flutter possuía somente a
tela inicial da marca e o botão “Começar” ainda não navegava. As demais telas,
Firebase, gráficos e interações eram itens planejados — esse texto descreve apenas
o estado histórico do CP4, não o estado atual do aplicativo.

### Problema e público-alvo

Muitas pessoas conseguem visualizar seus gastos, mas têm dificuldade para entender
quanto podem guardar, organizar as finanças e transformar essas informações em um
plano realista. O público-alvo inicial são jovens adultos e pessoas que desejam
organizar sua vida financeira e criar planos claros para objetivos pessoais.

### Solução e diferencial propostos

A proposta é ir além do registro de gastos: relacionar informações financeiras,
metas e planos em linguagem simples. O modelo de negócio acadêmico considerado é
freemium, com uma base gratuita para controle e metas e uma possível versão
premium com análises avançadas.

### Evolução do escopo planejado

O fluxo imaginado no CP4 incluía login, conexão a uma conta Sandbox, organização
de transações, cálculo de renda e despesas, criação de metas e explicação por IA.
No CP5 foram implementados login real, dashboard, transações simuladas, metas com
Firestore e assistente determinístico. Pluggy Sandbox e IA real continuam fora do
escopo concluído.
