# Divisor de Arquivos

App em Flutter que divide arquivos grandes em várias partes menores, junta
múltiplos arquivos em um único e permite visualizar o conteúdo de arquivos de
texto. Totalmente em português do Brasil.

## Funcionalidades

- **Dividir arquivos grandes**: escolha um arquivo e o tamanho (MB) de cada
  parte. O app gera partes numeradas (`nome_parte001.ext`, `nome_parte002.ext`...).
- **Juntar múltiplos arquivos**: selecione as partes (qualquer ordem — o app
  ordena naturalmente) e informe o nome do arquivo final.
- **Visualizar conteúdo**: leia o conteúdo de arquivos de texto (até 10 MB).

## Como compilar localmente

```bash
flutter pub get
flutter run          # em um dispositivo/emulador
flutter build apk --release   # gera o APK
```

## APK via GitHub Actions

Ao enviar código para a branch `main`, um workflow compila automaticamente o
APK de release e o disponibiliza como artefato. Veja em
**Actions** no repositório.

O APK gerado fica em:
`build/app/outputs/flutter-apk/app-release.apk`

> O build de release usa a chave de assinatura de debug (padrão do Flutter).
> Para publicar na Play Store, configure uma keystore própria.

## Estrutura

```
lib/
├── main.dart                  # Entrada do app (tema, locale pt-BR)
├── screens/
│   ├── home_screen.dart       # Menu com as 3 opções
│   ├── split_screen.dart      # Dividir arquivos
│   ├── merge_screen.dart      # Juntar arquivos
│   └── view_screen.dart       # Visualizar conteúdo
└── services/
    └── arquivo_utils.dart     # Lógica de dividir/juntar/ler arquivos
```