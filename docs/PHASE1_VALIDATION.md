# Phase 1 — Autenticación y validación

Estado de referencia: 2026-10-15. Implementación terminada; validación parcial en
dispositivo. La prueba con segunda cuenta está aplazada por petición del usuario:
no dispone de otra cuenta actualmente. No hay pruebas manuales en curso.
Este documento registra únicamente Phase 1; el avance posterior de grupos y
membresías se registra en docs/PHASE2_VALIDATION.md. Los pendientes de auth
descritos aquí se mantienen hasta una comprobación explícita.

## Implementación

- Login Google con Firebase Authentication y cierre de sesión.
- Restauración mediante el estado persistido de Firebase Authentication.
- Rutas `/login`, `/loading` y `/`; redirects según sesión.
- Perfil `users/{uid}` creado/actualizado mediante transacción y leído del servidor.
  `createdAt` se conserva; `updatedAt` y `lastSignInAt` usan hora del servidor.
  `lastSignInAt` registra acceso de sesión a la app, incluida restauración.
- Perfiles sin roles ni permisos globales. Acceder con Google no concede membresía.
- Carga, errores comprensibles, cancelación, bloqueo de doble envío y reintento.
  El reintento del perfil es explícito; no hay reintentos automáticos con escrituras.
- Separación de auth en models, services, repositories y providers. El router y
  la composición de la app mantienen su ubicación previa; no se migraron otras features.

## Comprobado automáticamente

| Comprobación | Resultado |
| --- | --- |
| `dart format lib test` | Correcto |
| `flutter analyze --no-pub` | Sin incidencias |
| `flutter test --no-pub` | 8 pruebas superadas |
| `flutter build apk --debug --no-pub` | APK generado |
| Reglas en Firestore Emulator | 4 pruebas superadas |
| Despliegue de reglas | Correcto, proyecto `boteparroquial`, base `(default)` |

Las pruebas Flutter cubren login/logout, protección de rutas, restauración simulada,
cambio de cuenta sin mostrar el perfil anterior, error/reintento de perfil,
cancelación y bloqueo de doble envío; además de bootstrap y rutas de datos.
Las pruebas de reglas cubren perfil propio, acceso anónimo/ajeno, validación de
campos/timestamps, prohibición de roles/listado/borrado y cierre de datos de grupo.

## Prueba real en A059P

Dispositivo detectado por Flutter: Android 16 (API 36), arm64.

- Instalación y arranque: comprobados por Flutter, proceso y pantalla de acceso.
- Primera cuenta Google: Firebase notificó sesión autenticada y el usuario confirmó
  su nombre y «Tu perfil está guardado y tu sesión está activa».
- Logout: Firebase y Google notificaron cierre; la app volvió a login.
- Reinicio sin sesión: volvió a la pantalla de login.
- Reinicio con sesión abierta: pendiente de comprobar sin logout previo.
- Segunda cuenta real: aplazada por petición del usuario el 2026-10-15, por no
  disponer de otra cuenta ahora. Sigue siendo criterio pendiente de cierre del roadmap.
- iOS: configuración preservada; no compilado/probado desde Windows.

## Pendientes para retomar más adelante

| Prueba | Estado | Qué hace falta |
| --- | --- | --- |
| Segunda cuenta Google real | Aplazada por el usuario | Otra cuenta disponible y que el usuario solicite retomar la prueba |
| Restauración después de cerrar y abrir el proceso | Pendiente, no comprobada | Android conectado con una sesión abierta; puede hacerse con la primera cuenta |

No dar Phase 1 por completamente validada ni presentar las pruebas simuladas
como evidencia de dos cuentas reales. No volver a pedir la segunda cuenta mientras
el usuario no indique que quiere retomar esa comprobación.

Cuando el usuario solicite continuar:

1. Conectar el Android y confirmar el dispositivo con `flutter devices`.
2. Entrar con una cuenta, verificar su nombre y el mensaje de perfil guardado,
   y dejar la sesión abierta sin pulsar «Cerrar sesión».
3. Reiniciar únicamente el proceso de la app, sin borrar datos ni desinstalar.
   Confirmar que vuelve al perfil de la misma cuenta sin pedir login.
4. Cerrar sesión y comprobar que vuelve al login y no muestra el perfil anterior.
5. Cuando haya segunda cuenta, seleccionarla manualmente en Google, confirmar
   su perfil propio y que no se muestra información de la cuenta anterior.
6. Registrar los resultados reales aquí y actualizar README.md y docs/ROADMAP.md.

El cierre completo de Phase 1 requiere la prueba pendiente de dos cuentas del
roadmap. Este registro no inicia otras fases ni modifica la aplicación.

## Reproducir las pruebas de reglas

Desde `tools/firestore-rules/`, ejecutar `npm ci` para instalar las dependencias
fijadas por `package-lock.json`. Desde la raíz del repositorio:

```sh
firebase emulators:exec --only firestore --project demo-boteparroquial "node --test tools/firestore-rules/profile_rules.test.cjs"
```

Requiere Java 21 o posterior disponible para Firebase CLI. Este entorno usa el JDK
incluido con Android Studio. Las pruebas usan un proyecto `demo-` y no escriben en
Firestore real. Los mensajes PERMISSION_DENIED de los casos negativos son esperados.

Las reglas del perfil están en `firestore.rules`; Firebase Console y el archivo
local deben mantenerse coherentes. No abrir grupos hasta implementar sus reglas
en Phase 2 ni usar credenciales administrativas en la aplicación móvil.
