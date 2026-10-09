# Axios

**Seu planejamento financeiro, de forma inteligente.**

## Integrantes

- Amom Ianaguivara — 565718 
- Fernando Antônio — 562549
- Gabriel Ramos Moreira — 564074
- Vinicius Mello Siqueira — 565257
- Victor Chen — 565363

## Descrição do projeto

O Axios é um projeto acadêmico de aplicativo mobile de planejamento financeiro,
desenvolvido em Flutter e Dart. Sua proposta é criar um assistente financeiro
pessoal inteligente que transforme os hábitos financeiros do usuário em planos
concretos para atingir seus objetivos.

## Problema

Muitas pessoas conseguem visualizar seus gastos, mas têm dificuldade para entender
quanto podem guardar, organizar suas finanças e transformar essas informações em
um plano realista para atingir metas financeiras.

## Solução proposta

O aplicativo pretende reunir a organização dos gastos, a criação de metas e o
cálculo de planos financeiros. Um assistente com IA explicará esses planos em
linguagem natural, usando os dados financeiros do usuário como contexto.

Nesta primeira etapa, o aplicativo apresenta apenas a tela inicial da marca.
Os recursos financeiros e as integrações descritos a seguir são planejados.

## Público-alvo

Jovens adultos e pessoas que desejam organizar melhor sua vida financeira,
acompanhar gastos e criar planos claros para atingir objetivos pessoais.

## Principais funcionalidades do MVP planejado

- Login simples.
- Dashboard financeiro.
- Transações provenientes do Pluggy Sandbox.
- Categorização de gastos.
- Criação de metas financeiras.
- Cálculo de quanto guardar por mês.
- Assistente com IA usando os dados financeiros do usuário.
- Gráficos básicos de gastos.
- Acompanhamento da evolução das metas.

## Fluxo principal do produto

Fluxo previsto para o MVP, ainda não implementado:

1. O usuário entra no aplicativo.
2. Conecta uma conta fictícia do Sandbox.
3. O aplicativo recebe as transações.
4. Organiza os gastos por categoria.
5. Calcula renda, despesas e sobra.
6. O usuário cria uma meta.
7. O motor financeiro calcula um plano.
8. A IA explica esse plano em linguagem natural.

## Identidade visual

A marca parte dos conceitos de clareza, crescimento, inteligência financeira e
planejamento. O nome Axios acompanha a tagline “Seu planejamento financeiro,
de forma inteligente.”

| Cor | Código | Uso na tela inicial |
| --- | --- | --- |
| Off White | `#FAF8F2` | Fundo |
| Axios Gold | `#E6B800` | Botão principal |
| Gold Soft | `#F4E7B7` | Fundo do ícone de crescimento |
| Graphite | `#1F2937` | Textos principais |
| Gray | `#6B7280` | Texto secundário |

A tipografia planejada utiliza **Manrope** para marca, títulos e destaques e
**Inter** para textos e interface. A tela inicial utiliza a tipografia padrão do
Flutter, sem dependências adicionais de fontes. A identidade visual inicial foi
definida no Figma.

### Naming rationale

O nome Axios é inspirado em uma palavra de origem grega associada a valor, mérito
e importância. Essa inspiração se relaciona à proposta de ajudar o usuário a
compreender o valor do dinheiro e direcioná-lo aos seus objetivos, por meio de
um planejamento financeiro claro.

### Tom de voz

- **Claro:** explicar informações e conceitos financeiros com linguagem simples,
  evitando termos técnicos sem explicação.
- **Inteligente:** conectar os dados financeiros aos objetivos do usuário e
  explicar o raciocínio por trás dos planos propostos.
- **Acessível:** acolher pessoas com diferentes níveis de conhecimento financeiro,
  sem julgamentos sobre seus hábitos ou dúvidas.
- **Objetivo:** apresentar informações e próximos passos de forma direta,
  ajudando o usuário a entender o que pode fazer para organizar suas finanças.

## Tecnologias

| Tecnologia | Situação |
| --- | --- |
| Flutter e Dart | Utilizados na estrutura do aplicativo e na tela inicial |
| Backend | Implementação futura; tecnologia a definir |
| Pluggy Sandbox | Integração futura com transações de contas fictícias |
| Banco de dados | Implementação futura; tecnologia a definir |
| IA | Integração futura para explicar planos financeiros |

## Modelo de negócio

O modelo inicial proposto é freemium. Uma versão gratuita permitiria controle
financeiro e metas básicas. Uma versão premium poderia oferecer análises mais
avançadas, mais recursos do assistente inteligente e projeções personalizadas.

## Diferencial competitivo

A proposta vai além do registro e da visualização de gastos: transformar os dados
financeiros do usuário em recomendações práticas, metas e planos explicados de
forma simples por um assistente inteligente.

## Roadmap futuro

- Implementar login simples e dashboard financeiro.
- Definir e implementar o backend e o banco de dados.
- Integrar o Pluggy Sandbox e organizar transações por categoria.
- Implementar metas e o cálculo de quanto guardar mensalmente.
- Adicionar gráficos básicos de gastos e evolução das metas.
- Integrar o assistente com IA para explicar os planos financeiros.

## Status atual do projeto

Esta primeira etapa contempla:

- Definição da ideia.
- Branding inicial.
- Identidade visual no Figma.
- Estrutura Flutter criada.
- Tela inicial com nome, tagline, mensagem de apoio e botão “Começar”.
- Documentação inicial.

O botão “Começar” é apenas visual e ainda não realiza navegação. Não há backend,
banco de dados, autenticação real, integração com Pluggy ou IA, gráficos funcionais
ou outras telas implementadas.

## Como executar

Com o Flutter instalado, um SDK Dart compatível com o `pubspec.yaml` e um
dispositivo ou emulador configurado, execute na raiz do projeto:

```sh
flutter pub get
flutter run
```

Para listar os dispositivos disponíveis, utilize `flutter devices`. Caso seja
necessário selecionar um deles, execute `flutter run -d <id-do-dispositivo>`.

## Verificações

```sh
dart format .
flutter analyze
flutter test
```

## Estrutura inicial

```text
lib/
  main.dart                 # Inicialização e tema do aplicativo
  screens/
    home_screen.dart        # Tela inicial do Axios
test/
  widget_test.dart           # Teste de apresentação e do botão inicial
```

---

## Checkpoint 5 — Protótipo funcional

> As seções anteriores registram o escopo e o estado acadêmico do Checkpoint 4.
> A partir deste ponto está documentada a evolução implementada no CP5.

### Funcionalidades do CP5

- Cadastro, login e logout com e-mail e senha pelo Firebase Authentication quando
  o projeto Firebase está configurado.
- Modo de demonstração explicitamente identificado para desenvolvimento local e
  testes sem credenciais externas.
- Dashboard com renda, gastos, saldo, gráfico por categoria e resumo da meta.
- Transações simuladas com busca, filtros de receitas/despesas e estado vazio.
- Metas com progresso calculado, formulário de criação, plano mensal e persistência
  no Cloud Firestore quando o Firebase está ativo.
- Assistente demonstrativo com mensagens determinísticas e cálculos feitos sobre os
  mesmos dados financeiros do aplicativo. Não há IA externa neste checkpoint.
- Navegação inferior entre Início, Transações, Metas e Assistente com preservação do
  estado das abas por `IndexedStack`.
- Layouts responsivos, áreas seguras, conteúdo rolável e alvos de toque adequados.

O conjunto simulado representa renda de R$ 3.000,00, gastos de R$ 2.150,00 e
sobra de R$ 850,00. Categorias e gráfico são derivados das mesmas transações. Na
meta Viagem, os R$ 1.500,00 acumulados são descontados do objetivo de R$ 6.000,00:
guardando R$ 500,00 por mês, faltam 9 meses.

### Arquitetura adotada

```text
lib/
  app.dart                    # MaterialApp e gate de autenticação
  app_dependencies.dart       # Injeção simples e seleção Firebase/demonstração
  core/
    theme/                    # Cores, tipografia e tema
    utils/                    # Formatação monetária e de datas
  data/                       # Fonte central de dados simulados
  models/                     # Usuário, transação, resumo, meta e mensagem
  repositories/              # Contratos e implementações Firebase/em memória
  services/                   # Inicialização segura do Firebase
  state/                      # AppController (ChangeNotifier)
  screens/                    # Login, cadastro, shell e quatro telas principais
  widgets/                    # Logo, cards, gráfico, cabeçalho e navegação
test/
  financial_calculations_test.dart
  navigation_test.dart
  transaction_filter_test.dart
  widget_test.dart
firestore.rules               # Isolamento dos dados por UID autenticado
```

A solução usa apenas `ChangeNotifier`, abstrações de repositório e componentes
nativos do Flutter. Isso mantém o protótipo simples e deixa os serviços externos
substituíveis em testes.

### Dependências principais

| Dependência | Uso |
| --- | --- |
| `firebase_core` | Inicialização da aplicação Firebase |
| `firebase_auth` | Cadastro, login, sessão e logout |
| `cloud_firestore` | Persistência das metas em `users/{uid}/goals` |
| `flutter_svg` | Renderização local da logo vetorial do Figma |
| `intl` | Formatação de moeda e datas em português |

As fontes Inter e Manrope estão empacotadas em `assets/fonts`, evitando download em
tempo de execução.

### Configuração do Firebase

O repositório não contém credenciais de um projeto Firebase. Para ativar a
integração real:

1. Crie ou selecione um projeto no Firebase Console.
2. Habilite **Authentication > Sign-in method > Email/Password**.
3. Crie um banco **Cloud Firestore**.
4. Instale o FlutterFire CLI no seu ambiente e, na raiz do projeto, execute
   `flutterfire configure` para Android (e outros targets nativos desejados).
5. Publique as regras de `firestore.rules` no Firebase Console ou com a Firebase
   CLI. Elas permitem que cada usuário acesse apenas `users/{seuUid}`.

No Web, o protótipo também aceita a configuração por `dart-define`, sem gravar
valores no repositório:

```sh
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

Sem a configuração, o aplicativo inicia em modo de demonstração, mostra esse fato
na tela de login e usa autenticação/metas somente em memória. Esse fallback existe
para preview e testes; ele não deve ser confundido com persistência real.

### Execução e testes

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```

Para Android:

```sh
flutter devices
flutter run -d <id-do-dispositivo>
flutter build apk --debug
```

### Decisões técnicas e limites conhecidos

- Transações, resumo financeiro e categorias são simulados e centralizados; o
  Pluggy Sandbox continua fora do escopo do CP5.
- O Assistente Axios é determinístico e se identifica como simulado; integração
  com IA é etapa futura.
- As metas de usuários autenticados são persistidas no Firestore e metas de exemplo
  são inseridas somente quando a coleção do usuário está vazia.
- A configuração de um projeto Firebase, a ativação dos serviços no Console e a
  publicação das regras são ações externas obrigatórias.
- O projeto não contém chaves administrativas, service accounts ou senhas.

### Próximos passos até o APK final

1. Configurar o projeto Firebase acadêmico e validar cadastro, sessão e persistência
   em Android e Web.
2. Executar o conjunto completo de análise, testes e build em uma máquina com o
   Flutter/Android SDK disponíveis.
3. Fazer QA em aparelho Android físico, incluindo teclado, tamanhos de fonte e telas
   pequenas.
4. Na etapa futura do MVP, integrar Pluggy Sandbox e IA real mantendo os contratos
   de repositório existentes.
