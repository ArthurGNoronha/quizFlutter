# Quiz Flutter

Este projeto é um aplicativo de quiz desenvolvido em Flutter. O objetivo do app é apresentar perguntas de múltipla escolha para o usuário, exibindo imagens e alternativas, e ao final mostrar o resultado do quiz. As perguntas são extraídas do banco de dados Firebase.

## Funcionalidades

- Perguntas com alternativas e imagens.
- Integração com Firebase para armazenamento e análise.
- Registro de erros com Firebase Crashlytics.
- Ranking local dos melhores resultados utilizando shared preferences.

## Pré-requisitos

- [Flutter](https://flutter.dev/docs/get-started/install) instalado na máquina.
- Conta no [Firebase](https://console.firebase.google.com/) (opcional, caso queira customizar o backend).
- Android Studio, VS Code ou outro editor compatível.

## Como executar o projeto

1. **Clone o repositório:**
    ```sh
    git clone https://github.com/arthurgnoronha/quizFlutter
    cd quiz_flutter
    ```

2. **Instale as dependências:**
    ```sh
    flutter pub get
    ```

3. **Execute na plataforma desejada:**
    ```sh
    flutter run -d chrome
    ```
    *Substitua "chrome" pelo navegador ou dispositivo desejado.*

    **Ou, para gerar o APK para Android:**
    ```sh
    flutter build apk --release
    ```

## Demonstração do Quiz:

1. Pergunta Padrão:
    ![Padrão](assets/padrao.png)

2. Pergunta Correta:
    ![Correta](assets/correta.png)

3. Pergunta Incorreta:
    ![Incorreta](assets/incorreta.png)

4. Tela Final
    ![Final](assets/final.png)

5. Ranking (Local apenas):
    ![Ranking](assets/ranking.png)
