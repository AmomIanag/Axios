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
