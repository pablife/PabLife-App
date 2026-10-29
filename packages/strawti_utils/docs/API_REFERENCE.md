# API Reference - Strawti Utils

Referência completa da API do package `strawti_utils`.

## 📋 Índice

- [Modelo de Resposta](#modelo-de-resposta)
- [Widgets](#widgets)
- [Validadores](#validadores)
- [Helpers](#helpers)
- [In-App Review](#in-app-review)
- [In-App Update](#in-app-update)
- [Tratamento de Erros](#tratamento-de-erros)

## Modelo de Resposta

### StrautilsResponse<T>

Modelo principal para respostas padronizadas.

#### Construtores

```dart
// Sucesso
StrautilsResponse.success(T data, {String message = ''})

// Aviso
StrautilsResponse.warning(String message, {
  dynamic data,
  Future<StrautilsResponse<T>> Function()? tryAgain,
})

// Erro
StrautilsResponse.error(String message, {
  dynamic data,
  Future<StrautilsResponse<T>> Function()? tryAgain,
  Object? error,
})
```

#### Propriedades

| Propriedade | Tipo                               | Descrição                                  |
| ----------- | ---------------------------------- | ------------------------------------------ |
| `status`    | `StrautilsResponseTypes`           | Status da resposta (success/warning/error) |
| `data`      | `T?`                               | Dados retornados                           |
| `message`   | `String`                           | Mensagem para exibição                     |
| `tryAgain`  | `FStrautilsResponse<T> Function()` | Função para nova tentativa                 |
| `error`     | `Object?`                          | Exceção capturada (apenas em error)        |

#### Getters

| Getter    | Tipo   | Descrição                  |
| --------- | ------ | -------------------------- |
| `success` | `bool` | `true` se status é success |
| `error`   | `bool` | `true` se status é error   |
| `warning` | `bool` | `true` se status é warning |

#### Tipos

```dart
enum StrautilsResponseTypes { success, warning, error }
typedef FStrautilsResponse<T> = Future<StrautilsResponse<T>>
```

## Widgets

### StrautilsResponseFutureBuilder<T>

Widget para trabalhar com `StrautilsResponse` de forma declarativa.

#### Construtor

```dart
StrautilsResponseFutureBuilder<T>({
  Key? key,
  required FStrautilsResponse<T> futureResponse,
  required Widget Function(BuildContext context, T data) builder,
  Widget Function(BuildContext context)? loadingBuilder,
  Widget Function(BuildContext context)? emptyBuilder,
  Widget Function(BuildContext context, Object? error, String message, void Function() tryAgain)? errorBuilder,
  Widget Function(BuildContext context, String message, void Function() tryAgain)? warningBuilder,
  void Function(BuildContext context, int currentAttempt, int maxAttempts)? onMaxAttempts,
  int maxAttempts = 3,
})
```

#### Parâmetros

| Parâmetro        | Tipo                                                               | Obrigatório | Descrição                                       |
| ---------------- | ------------------------------------------------------------------ | ----------- | ----------------------------------------------- |
| `futureResponse` | `FStrautilsResponse<T>`                                            | ✅          | Future que será executado                       |
| `builder`        | `Widget Function(BuildContext, T)`                                 | ✅          | Widget para dados válidos                       |
| `loadingBuilder` | `Widget Function(BuildContext)?`                                   | ❌          | Widget durante carregamento                     |
| `emptyBuilder`   | `Widget Function(BuildContext)?`                                   | ❌          | Widget para dados vazios                        |
| `errorBuilder`   | `Widget Function(BuildContext, Object?, String, void Function())?` | ❌          | Widget para erros                               |
| `warningBuilder` | `Widget Function(BuildContext, String, void Function())?`          | ❌          | Widget para avisos                              |
| `onMaxAttempts`  | `void Function(BuildContext, int, int)?`                           | ❌          | Callback quando limite de tentativas é atingido |
| `maxAttempts`    | `int`                                                              | ❌          | Número máximo de tentativas (padrão: 3)         |

## Validadores

### validateEmail

Valida formato de email.

```dart
String? validateEmail(
  String? value, {
  String emptyMessage = "Campo obrigatório!",
  String invalidMessage = "O email informado é inválido!",
})
```

#### Parâmetros

| Parâmetro        | Tipo      | Obrigatório | Descrição                    |
| ---------------- | --------- | ----------- | ---------------------------- |
| `value`          | `String?` | ✅          | Email a ser validado         |
| `emptyMessage`   | `String`  | ❌          | Mensagem para campo vazio    |
| `invalidMessage` | `String`  | ❌          | Mensagem para email inválido |

#### Retorno

- `null`: Email válido
- `String`: Mensagem de erro

### validateName

Valida formato de nome.

```dart
String? validateName(
  String? value, {
  String emptyMessage = "Campo obrigatório!",
  String invalidMessage = "O nome informado é inválido!",
})
```

#### Parâmetros

| Parâmetro        | Tipo      | Obrigatório | Descrição                   |
| ---------------- | --------- | ----------- | --------------------------- |
| `value`          | `String?` | ✅          | Nome a ser validado         |
| `emptyMessage`   | `String`  | ❌          | Mensagem para campo vazio   |
| `invalidMessage` | `String`  | ❌          | Mensagem para nome inválido |

#### Retorno

- `null`: Nome válido
- `String`: Mensagem de erro

### validateUsername

Valida formato de username.

```dart
String? validateUsername(
  String? value, {
  String emptyMessage = "Campo obrigatório!",
  String invalidMessage = "O username informado é inválido!",
  bool allowToEndWithAPeriod = false,
  bool allowToStartWithAPeriod = false,
  int maxLength = 30,
})
```

#### Parâmetros

| Parâmetro                 | Tipo      | Obrigatório | Descrição                             |
| ------------------------- | --------- | ----------- | ------------------------------------- |
| `value`                   | `String?` | ✅          | Username a ser validado               |
| `emptyMessage`            | `String`  | ❌          | Mensagem para campo vazio             |
| `invalidMessage`          | `String`  | ❌          | Mensagem para username inválido       |
| `allowToEndWithAPeriod`   | `bool`    | ❌          | Permite username terminando com ponto |
| `allowToStartWithAPeriod` | `bool`    | ❌          | Permite username começando com ponto  |
| `maxLength`               | `int`     | ❌          | Comprimento máximo (padrão: 30)       |

#### Retorno

- `null`: Username válido
- `String`: Mensagem de erro

## Helpers

### StrautilsDateTimeHelper

Utilitários para manipulação de datas.

#### Propriedades Estáticas

| Propriedade      | Tipo       | Descrição              |
| ---------------- | ---------- | ---------------------- |
| `nowWithoutTime` | `DateTime` | Data atual sem horário |

#### Métodos Estáticos

##### isEqualDate

```dart
static bool isEqualDate(DateTime a, DateTime b)
```

Compara apenas a data (ano, mês, dia).

##### isEqualTime

```dart
static bool isEqualTime(DateTime a, DateTime b)
```

Compara apenas o horário (hora, minuto, segundo).

##### isEqualDateTime

```dart
static bool isEqualDateTime(DateTime a, DateTime b)
```

Compara data e hora completas.

### ternaryClean

Função para operadores ternários mais limpos.

```dart
T ternaryClean<T>(
  bool condition, {
  required T caseTrue,
  required T caseFalse,
})
```

#### Parâmetros

| Parâmetro   | Tipo   | Obrigatório | Descrição                |
| ----------- | ------ | ----------- | ------------------------ |
| `condition` | `bool` | ✅          | Condição a ser avaliada  |
| `caseTrue`  | `T`    | ✅          | Valor retornado se true  |
| `caseFalse` | `T`    | ✅          | Valor retornado se false |

## In-App Review

### StrautilsInAppReview

Sistema para solicitar avaliações na loja de aplicativos.

#### Singleton

```dart
static final StrautilsInAppReview instance = StrautilsInAppReview._();
```

#### Métodos

##### initialize

```dart
Future<void> initialize({
  String? appStoreId,
})
```

Inicializa o sistema de avaliação.

| Parâmetro    | Tipo      | Obrigatório | Descrição                           |
| ------------ | --------- | ----------- | ----------------------------------- |
| `appStoreId` | `String?` | ❌          | App Store ID (obrigatório para iOS) |

##### isAvailable

```dart
Future<bool> isAvailable()
```

Verifica se a avaliação está disponível.

##### requestReview

```dart
Future<StrautilsResponse> requestReview()
```

Solicita avaliação do usuário.

#### Características

- Respeita intervalo de 30 dias entre solicitações
- Fallback para loja de aplicativos
- Não funciona em modo debug

## In-App Update

### StrautilsInAppUpdate

Sistema de atualizações automáticas para Android.

#### Métodos

##### updateApp

```dart
Future<StrautilsResponse> updateApp({
  bool performImmediateUpdate = false,
  bool startFlexibleUpdate = false,
})
```

Executa atualização do aplicativo.

| Parâmetro                | Tipo   | Obrigatório | Descrição                         |
| ------------------------ | ------ | ----------- | --------------------------------- |
| `performImmediateUpdate` | `bool` | ❌          | Atualização imediata (tela cheia) |
| `startFlexibleUpdate`    | `bool` | ❌          | Atualização flexível (background) |

#### Características

- Disponível apenas no Android
- Suporte a atualizações flexíveis e imediatas
- Verificação automática de disponibilidade

## Tratamento de Erros

### StrautilsTryThis

Interface para repositórios com tratamento automático de exceções.

#### Métodos

##### tryThis

```dart
FStrautilsResponse<T> tryThis<T>(
  TryThisFunction<T> callback, {
  StrautilsResponse<T> Function(Object error)? onCatch,
  TryThisFunction<T>? tryAgain,
  String action = "realizar operação",
})
```

Executa operação com tratamento automático de erros.

| Parâmetro  | Tipo                                     | Obrigatório | Descrição                  |
| ---------- | ---------------------------------------- | ----------- | -------------------------- |
| `callback` | `TryThisFunction<T>`                     | ✅          | Função a ser executada     |
| `onCatch`  | `StrautilsResponse<T> Function(Object)?` | ❌          | Tratamento customizado     |
| `tryAgain` | `TryThisFunction<T>?`                    | ❌          | Função para nova tentativa |
| `action`   | `String`                                 | ❌          | Descrição da ação          |

#### Tipos

```dart
typedef TryThisFunction<T> = FStrautilsResponse<T> Function()
```

### StrautilsDefaultErrors

Mensagens de erro padronizadas.

#### Propriedades Estáticas

| Propriedade         | Tipo     | Descrição            |
| ------------------- | -------- | -------------------- |
| `socketException`   | `String` | Problemas de conexão |
| `noSuchMethodError` | `String` | Dados inesperados    |
| `timeoutException`  | `String` | Timeout de operações |
| `formatException`   | `String` | Formato inválido     |

#### Métodos Estáticos

##### unknowError

```dart
static String unknowError(String action, [Object? error, StackTrace? stack])
```

Gera mensagem de erro genérica.

| Parâmetro | Tipo          | Obrigatório | Descrição                       |
| --------- | ------------- | ----------- | ------------------------------- |
| `action`  | `String`      | ✅          | Ação que estava sendo executada |
| `error`   | `Object?`     | ❌          | Erro ocorrido                   |
| `stack`   | `StackTrace?` | ❌          | Stack trace do erro             |

## �� Configurações

### Arquivos de Export

O package oferece diferentes arquivos de export para diferentes necessidades:

#### strawti_utils.dart (Principal)

```dart
import 'package:strawti_utils/strawti_utils.dart';
```

Exporta todos os componentes do package.

#### utils.dart (Utilitários Básicos)

```dart
import 'package:strawti_utils/utils.dart';
```

Exporta apenas helpers e utilitários básicos:

- `StrautilsDateTimeHelper`
- `ternaryClean`

#### infra.dart (Infraestrutura)

```dart
import 'package:strawti_utils/infra.dart';
```

Exporta apenas componentes de infraestrutura:

- `StrautilsResponse<T>`
- `StrautilsTryThis`
- `StrautilsDefaultErrors`

### Dependências

O package utiliza as seguintes dependências:

```yaml
dependencies:
  get_storage: ^2.1.1
  in_app_review: ^2.0.9
  in_app_update: ^4.2.3
```

### Permissões Android

Para In-App Updates, adicione ao `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### Versão do SDK

```yaml
environment:
  sdk: ^3.5.1
```

## 📝 Notas Importantes

### Logging

O package inclui sistema de logging automático:

- **StrautilsResponse**: Logs automáticos para success, warning e error
- **StrautilsTryThis**: Logs para tratamento customizado de erros
- **StrautilsDefaultErrors**: Logs para erros desconhecidos

Os logs usam `dart:developer` e incluem contexto relevante para debugging.

### In-App Review

- Não funciona em modo debug
- Respeita diretrizes da Apple/Google
- Intervalo mínimo de 30 dias entre solicitações

### In-App Update

- Disponível apenas no Android
- Requer instalação via Google Play
- Não funciona em ambiente de desenvolvimento

### Tratamento de Erros

- Trata automaticamente exceções comuns
- Permite tratamento customizado via `onCatch`
- Fornece mensagens padronizadas em português

### Widgets

- Suporte a retry automático
- Builders customizáveis
- Controle de tentativas máximas
