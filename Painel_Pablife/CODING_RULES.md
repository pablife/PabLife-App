# Regras de Código - Painel Pablife

Este documento define as convenções e padrões de código que devem ser seguidos no projeto.

## 📋 Índice

- [Arquitetura de Widgets](#arquitetura-de-widgets)
- [Gerenciamento de Estado](#gerenciamento-de-estado)
- [Tratamento de Erros](#tratamento-de-erros)
- [Repositórios](#repositórios)

---

## 🎨 Arquitetura de Widgets

### ✅ Páginas e Widgets sempre Stateless

**Regra:** Todas as páginas e widgets devem ser **StatelessWidget**.

**❌ Evitar:**

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}
```

**✅ Correto:**

```dart
class MyPage extends StatelessWidget {
  const MyPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyController>(
      builder: (controller) {
        return Scaffold(...);
      },
    );
  }
}
```

### ✅ Extração de Widgets em Arquivos Separados

**Regra:** Widgets complexos ou reutilizáveis devem ser extraídos para arquivos separados como classes independentes.

**Estrutura recomendada:**

```
lib/
  modules/
    banners/
      banners_page.dart
      banners_controller.dart
      banners_routes.dart
      widgets/
        banner_list_item.dart
        banner_form_dialog.dart
```

**Exemplo:**

```dart
// widgets/banner_list_item.dart
class BannerListItem extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BannerListItem({
    super.key,
    required this.banner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}
```

---

## 🔄 Gerenciamento de Estado

### ✅ Usar GetBuilder (NUNCA Obx)

**Regra:** Use **sempre** `GetBuilder` para gerenciamento de estado. **NUNCA** use `Obx` ou variáveis `.obs`.

**❌ Evitar:**

```dart
class MyController extends GetxController {
  var counter = 0.obs; // ❌ NÃO usar .obs
  
  void increment() {
    counter++; // ❌ NÃO usar observáveis
  }
}

// Na view
Obx(() => Text('${controller.counter}')) // ❌ NÃO usar Obx
```

**✅ Correto:**

```dart
class MyController extends GetxController {
  int counter = 0; // ✅ Variável normal
  
  void increment() {
    counter++;
    update(); // ✅ Atualizar manualmente
  }
}

// Na view
GetBuilder<MyController>(
  builder: (controller) {
    return Text('${controller.counter}');
  },
)
```

**Exemplo completo:**

```dart
// Controller
class BannersController extends GetxController {
  List<BannerModel> banners = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    update(); // Notifica a UI
    
    final response = await _repository.getAll();
    banners = response.data ?? [];
    
    isLoading = false;
    update(); // Notifica a UI novamente
  }
}

// Page
class BannersPage extends StatelessWidget {
  const BannersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannersController>(
      builder: (controller) {
        if (controller.isLoading) {
          return AppWidgetLoading();
        }
        
        return ListView.builder(
          itemCount: controller.banners.length,
          itemBuilder: (context, index) {
            return BannerListItem(banner: controller.banners[index]);
          },
        );
      },
    );
  }
}
```

---

## ⚠️ Tratamento de Erros

### ✅ Evitar Try-Catch na Controller

**Regra:** O tratamento de exceções deve ser feito **exclusivamente nos repositórios**. As controllers devem apenas verificar o sucesso da operação.

**❌ Evitar na Controller:**

```dart
Future<void> loadData() async {
  try {
    final data = await _repository.getData();
    items = data;
  } catch (e) { // ❌ NÃO fazer try-catch na controller
    print('Error: $e');
  }
}
```

**✅ Correto na Controller:**

```dart
Future<void> loadData() async {
  isLoading = true;
  update();
  
  final response = await _repository.getData();
  
  if (response.success) {
    items = response.data ?? [];
  } else {
    // Apenas mostrar mensagem ao usuário
    AppSnackbar.to.error('Não foi possível carregar os dados');
  }
  
  isLoading = false;
  update();
}
```

---

## 🗄️ Repositórios

### ✅ Usar FStrautilsResponse SEMPRE

**Regra:** Todos os métodos de repositório devem retornar `FStrautilsResponse<T>` e usar o wrapper `tryThis()` do `StrautilsTryThis`.

**Estrutura obrigatória:**

```dart
class MyRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<MyModel>> getAll() async {
    return tryThis<List<MyModel>>(
      () async {
        final response = await _client
            .from('my_table')
            .select()
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((item) => MyModel.fromMap(item))
            .toList();
        
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAll(),
      action: 'buscar dados',
    );
  }

  FStrautilsResponse<bool> create(MyModel model) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('my_table')
            .insert(model.toMap());
        
        return StrautilsResponse.success(true);
      },
      tryAgain: () => create(model),
      action: 'criar registro',
    );
  }

  FStrautilsResponse<bool> update(MyModel model) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('my_table')
            .update(model.toMap())
            .eq('id', model.id);
        
        return StrautilsResponse.success(true);
      },
      tryAgain: () => update(model),
      action: 'atualizar registro',
    );
  }

  FStrautilsResponse<bool> delete(String id) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('my_table')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
        
        return StrautilsResponse.success(true);
      },
      tryAgain: () => delete(id),
      action: 'deletar registro',
    );
  }
}
```

### 📊 Tipos de Retorno Comuns

| Operação | Tipo de Retorno |
|----------|----------------|
| Buscar lista | `FStrautilsResponse<List<Model>>` |
| Buscar por ID | `FStrautilsResponse<Model?>` |
| Criar | `FStrautilsResponse<Model?>` ou `FStrautilsResponse<bool>` |
| Atualizar | `FStrautilsResponse<bool>` |
| Deletar | `FStrautilsResponse<bool>` |
| Contar | `FStrautilsResponse<int>` |

### 🎯 Acessando Dados na Controller

```dart
// Verificar sucesso
final response = await _repository.getData();
if (response.success) {
  data = response.data ?? defaultValue;
} else {
  AppSnackbar.to.error('Operação falhou');
}

// Ou usar diretamente com operador ??
data = response.data ?? defaultValue;
```

---

## 📝 Resumo das Regras

1. ✅ **Páginas/Widgets**: Sempre `StatelessWidget`
2. ✅ **Extração de Widgets**: Criar arquivos separados como classes
3. ✅ **Estado**: Usar `GetBuilder`, **NUNCA** `Obx`
4. ✅ **Try-Catch**: Apenas nos repositórios (não nas controllers)
5. ✅ **Repositórios**: Sempre usar `FStrautilsResponse<T>` com `tryThis()`
6. ✅ **Base Class**: Todos os repositórios devem `extends StrautilsTryThis`
7. ✅ **Atualização Manual**: Sempre chamar `update()` após mudanças de estado

---

## 🔍 Checklist de Code Review

- [ ] Página é `StatelessWidget`?
- [ ] Widgets complexos extraídos para arquivos separados?
- [ ] Usando `GetBuilder` (não `Obx`)?
- [ ] Sem variáveis `.obs`?
- [ ] Controller chama `update()` após mudanças?
- [ ] Sem `try-catch` na controller?
- [ ] Repository retorna `FStrautilsResponse<T>`?
- [ ] Repository usa `tryThis()` wrapper?
- [ ] Repository extends `StrautilsTryThis`?
- [ ] Controller acessa `.data` e `.success` das respostas?

---

**Última atualização:** 18 de novembro de 2025
