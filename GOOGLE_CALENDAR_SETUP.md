# Configuração Google Calendar API

## 1. Google Cloud Console

### Criar Projeto
1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Clique em **Selecionar projeto** > **Novo projeto**
3. Nome: `Imperium App`
4. Clique em **Criar**

### Ativar API
1. No menu lateral, vá em **APIs e Serviços** > **Biblioteca**
2. Pesquise por **Google Calendar API**
3. Clique na API e depois em **Ativar**

### Configurar Tela de Consentimento OAuth
1. Vá em **APIs e Serviços** > **Tela de consentimento OAuth**
2. Selecione **Externo** e clique em **Criar**
3. Preencha:
   - Nome do app: `Imperium`
   - E-mail de suporte: seu email
   - Logo (opcional)
4. Em **Escopos**, adicione:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`
5. Em **Usuários de teste**, adicione seu email
6. Salve

### Criar Credenciais OAuth

#### Para iOS:
1. Vá em **APIs e Serviços** > **Credenciais**
2. Clique em **Criar credenciais** > **ID do cliente OAuth**
3. Tipo: **iOS**
4. Preencha:
   - Nome: `Imperium iOS`
   - Bundle ID: `com.imperium.app` (ou seu bundle ID)
5. Clique em **Criar**
6. Anote o **Client ID**

#### Para Android:
1. Clique em **Criar credenciais** > **ID do cliente OAuth**
2. Tipo: **Android**
3. Preencha:
   - Nome: `Imperium Android`
   - Package name: `com.imperium.app`
   - SHA-1: (veja abaixo como obter)
4. Clique em **Criar**

**Obter SHA-1 (Debug):**
```bash
cd android
./gradlew signingReport
```

**Obter SHA-1 (Release):**
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

---

## 2. Configuração iOS

### Info.plist
Adicione em `ios/Runner/Info.plist`:

```xml
<!-- Google Sign In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed Client ID do Google Cloud Console -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

**Onde encontrar o Reversed Client ID:**
- No Google Cloud Console, vá em Credenciais
- Clique no seu Client ID iOS
- Copie o "iOS URL scheme"

---

## 3. Configuração Android

### google-services.json
1. No Google Cloud Console, vá em **Configurações do projeto**
2. Selecione a aba **Android**
3. Baixe o `google-services.json`
4. Coloque em `android/app/google-services.json`

### build.gradle (projeto)
Em `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### build.gradle (app)
Em `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

---

## 4. Testar

```bash
cd /Users/iultra/Documents/Imperium-App/app
flutter pub get
flutter run
```

Na tela de **Agenda (Schedule)**:
1. Toque em **Conectar** no card do Google Calendar
2. Faça login com sua conta Google
3. Autorize o acesso ao Calendar
4. Eventos serão sincronizados

---

## 5. Publicação (Produção)

Antes de publicar:

1. **Verificar App no Google:**
   - Vá em **Tela de consentimento OAuth**
   - Clique em **Publicar app**
   - Complete a verificação (pode levar alguns dias)

2. **Escopos sensíveis:**
   - Calendar é escopo sensível
   - Google vai pedir justificativa de uso
   - Prepare uma descrição clara do uso

---

## Troubleshooting

### Erro: "Sign in failed"
- Verifique se o Bundle ID/Package name está correto
- Verifique se o SHA-1 está correto (Android)
- Verifique se a API está ativada

### Erro: "Access blocked"
- Adicione seu email como usuário de teste
- Ou publique o app para produção

### Erro: "Invalid client"
- Verifique se está usando o Client ID correto para a plataforma
- iOS usa Client ID diferente do Android

---

## Links Úteis

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Calendar API Docs](https://developers.google.com/calendar/api/v3/reference)
- [google_sign_in package](https://pub.dev/packages/google_sign_in)
- [googleapis package](https://pub.dev/packages/googleapis)
