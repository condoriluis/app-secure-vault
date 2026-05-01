# Vault - Gestor de Contraseñas Inteligente y Seguro

![Vault Banner](https://img.shields.io/badge/Security-AES--256-blue?style=for-the-badge&logo=shield)
![Flutter](https://img.shields.io/badge/Flutter-v3.x-02569B?style=for-the-badge&logo=flutter)
![State Management](https://img.shields.io/badge/Riverpod-State_Management-764ABC?style=for-the-badge&logo=dart)

**Vault** es una solución de seguridad personal de nivel profesional diseñada para proteger tus credenciales, tarjetas bancarias, identidades y notas bajo un esquema de cifrado **Zero-Knowledge**. Construida con Flutter, ofrece una experiencia de usuario premium, fluida y totalmente adaptable a cualquier dispositivo móvil.

## ✨ Características Principales

### 🛡️ Seguridad de Grado Militar
- **Cifrado AES-256**: Todos tus datos se cifran localmente antes de guardarse en la base de datos.
- **Zero-Knowledge**: Tus contraseñas maestras nunca salen de tu dispositivo.
- **Autenticación Dual**: Soporte completo para **Biometría** (Huella/Rostro) y **PIN de Seguridad**.
- **Bloqueo Automático**: Sistema de auto-bloqueo configurable al salir de la aplicación para prevenir accesos no autorizados.

### 🔑 Gestión Versátil de Bóvedas
- **Logins**: Almacena usuarios y contraseñas con soporte para copiado rápido.
- **Tarjetas de Crédito**: Visualización premium de tarjetas con enmascaramiento inteligente de números.
- **Identidades**: Guarda documentos de identidad, pasaportes y carnets de conducir de forma segura.
- **Notas Protegidas**: Espacio cifrado para información sensible en formato libre.
- **Generador 2FA (TOTP)**: Gestor de códigos de autenticación de dos factores integrado.

### 📸 Innovación en 2FA
- **Escáner QR Integrado**: Configura tus cuentas 2FA en segundos escaneando códigos QR de forma nativa.
- **Saneamiento Automático**: Limpieza y validación de claves secretas Base32 para asegurar la generación correcta de códigos.
- **Copiado Rápido**: Toca el código TOTP para copiarlo instantáneamente al portapapeles.

### 🎨 Experiencia de Usuario Premium
- **Diseño Adaptativo**: Interfaz fluida que escala perfectamente desde móviles pequeños hasta modelos Pro Max.
- **Temas Personalizables**: Elige entre múltiples paletas de colores y soporte completo para **Modo Oscuro**.
- **Tipografía Técnica**: Uso de `JetBrainsMono` para una lectura clara de códigos y números sensibles.
- **Búsqueda Avanzada**: Encuentra cualquier registro al instante con filtrado por categorías.

### 📦 Respaldo y Recuperación
- **Exportación Cifrada**: Crea respaldos `.vault` seguros de toda tu base de datos.
- **Importación Inteligente**: Sistema de recuperación robusto que permite importar respaldos incluso si el Master Salt ha cambiado, mediante verificación de Clave Maestra.

## 🛠️ Stack Tecnológico

- **Framework**: Flutter
- **Estado**: Riverpod (Notifier/StateNotifier)
- **Persistencia**: SQLite (sqflite)
- **Seguridad**: `flutter_secure_storage` para claves sensibles.
- **Plugins Destacados**:
  - `mobile_scanner`: Para escaneo de códigos QR.
  - `otp`: Para generación de códigos TOTP.
  - `local_auth`: Para autenticación biométrica.

## 🚀 Instalación y Uso

1. **Prerrequisitos**: Tener instalado Flutter SDK y las herramientas nativas de Android/iOS.
2. **Clonar**:
   ```bash
   git clone https://github.com/tu-usuario/vault.git
   ```
3. **Dependencias**:
   ```bash
   flutter pub get
   ```
4. **Ejecutar**:
   ```bash
   flutter run
   ```

---
*Desarrollado con enfoque en la privacidad y la excelencia visual.*
