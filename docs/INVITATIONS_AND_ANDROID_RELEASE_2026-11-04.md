# Invitaciones con imagen y distribución Android — D155–D156

## Implementado

- Grupo → Participantes → Invitar al grupo → Compartir invitación abre el
  selector nativo con imagen adjunta y texto. El destinatario se elige en WhatsApp;
  la app no envía mensajes automáticamente.
- Usa la foto privada actual del grupo; cuando no existe usa el logo incluido en
  assets/branding/bote_parroquial.png. No publica fotos ni modifica permisos Storage.
- Texto: `Te invito a «NOMBRE» en BoteParroquial. ¡Únete a nuestro grupo!`, seguido
  de enlace HTTPS y código. Copiar enlace/código conserva su comportamiento.
- Provider → InvitationShareRepository → servicios de invitaciones, fotos y
  compartición nativa. Lecturas remotas de foto y vista previa; revalidación de
  sesión/membresía/código antes de abrir el selector. Errores de permisos/red no
  se convierten en autorización ni permiten compartir una foto antigua de caché.
- Temporales por cuenta, limpieza al cambiar/salir y descarte del envío pendiente;
  carpeta creada sobre el directorio existente. WhatsApp controla la presentación
  final del adjunto/texto; pendiente probar en los teléfonos.

## Firma de distribución

El usuario elige clave independiente, sin reutilizar CoockieClikerRPG/GestorGastos.

- Clave: `C:\Users\aleja\Documents\keystores\BoteParroquial.jks`.
- Configuración privada de respaldo:
  `C:\Users\aleja\Documents\keystores\BoteParroquial-signing.properties`.
- Configuración local ignorada: `android/key.properties`. No enviar ninguno de
  estos tres archivos a usuarios ni subirlos a Git. Guardar copia privada fuera
  del portátil de la clave y la configuración: permiten firmar futuras actualizaciones.
- Alias: boteparroquial. RSA 3072, validez 10.000 días. Contraseñas aleatorias,
  sin imprimirlas ni pasarlas como argumento; keytool las recibe por entorno temporal.
- SHA-1: `C6:88:4E:FB:72:63:C5:D5:33:FD:05:B4:1E:68:73:7C:C5:C4:7E:52`.
- SHA-256: `3F:EB:42:27:3B:74:E5:42:46:7C:57:03:5A:17:DA:60:0B:5B:AD:11:22:88:C9:9C:C4:70:2D:05:16:3A:03:C5`.
- Huellas registradas en la app Android Firebase existente; configuración SDK
  descargada y comprobada con el cliente OAuth del certificado release.
- Hosting publicado únicamente para añadir el certificado a assetlinks.json;
  conserva también el de pruebas. Respaldo previo en
  `.dart_tool/assetlinks-before-release.json` (local, no archivado en Git).
- Gradle release usa distribution, nunca debug; si falta key.properties falla.
  Mantiene applicationId `com.example.bote_parroquial` y versión `1.0.0+1`.
  Incrementar build number al distribuir futuras actualizaciones.

## Validación

Tres casos dirigidos superados: foto + nombre/frase/enlace; fallback logo; rechazo
por permisos/cambio de sesión. `flutter analyze`: sin incidencias.

`flutter build apk --release` completado (277,1 s). APK universal para Android:
`C:\Users\aleja\Documents\GitHub\BoteParroquial\build\app\outputs\flutter-apk\app-release.apk`.
75.656.635 bytes (72,2 MiB); SHA-256 del APK:
`d4f8bcc134d90319fe2bf4ab01902e81d0756f98815e87754b9ed6f040a307cf`.
`apksigner verify --verbose --print-certs`: válido, esquema v2, un firmante RSA
3072 y SHA-256 coincidente con el certificado propio documentado. Hosting leído
tras publicar: incluye la huella release. key.properties y script temporal
confirmados como ignorados por Git.

No hay comprobación física todavía de esta firma, Google Sign-In, enlaces ni adjuntos WhatsApp. Usuario
instala/ejecuta. No se han cambiado Rules, documentos económicos, IAM ni secretos
de Supabase. No confundir esta clave Android local con credenciales de servidor.

## Recordatorios consultados, sin cambios

A las 10:00 del grupo, siete días y un día antes del último día del mes, recuperables
durante ese mismo día. No se programa otro el último día. Ambos usan:

- Persona: «Tienes una aportación pendiente. Abre el grupo para revisarla.»
- Resumen de gestores: «Hay aportaciones pendientes de revisar en tu grupo. Abre la app.»

Solo cuando hay pendiente; sin importes en push. Esta consulta no programa pruebas
ni acredita ninguna entrega nueva.
