# Copias diarias de consulta — 23/10/2026

## Alcance y comportamiento

D110–D112 resueltos por el usuario: siete copias diarias completas por móvil y
cuenta, datos Firestore y fotos según caché, Wi-Fi y datos móviles permitidos.
Es una función de consulta de la app, distinta de la copia semanal/visor de
portátil que permanece aplazada. No se ha creado ningún programador externo.

Al abrir/reanudar la app con sesión restaurada se comprueba el acceso en servidor.
Si no hay una copia válida de ese día, se captura. La descarga es independiente de
las pantallas abiertas y no bloquea el uso normal. Tras un fallo hay reintentos
acotados en primer plano; «Comprobar copia de hoy» permite intentarlo expresamente.
La primera captura completa del día se conserva; abrir de nuevo no descarga toda
la historia otra vez. Se siguen comprobando accesos. El día de archivo se calcula
desde la hora del servidor en Europe/Madrid, no desde un reloj del móvil alterado.
Si todavía no hay grupos accesibles, no se guarda un archivo vacío: al entrar en
el primer grupo se podrá preparar su copia ese mismo día.

Sin conexión se conserva la caché normal y se ofrece «Ver copias guardadas en este
móvil» desde Inicio y desde el aviso de actualización no confirmada del grupo.
El catálogo presenta fecha/hora real, grupos y cantidad de documentos. Ofrece la
última copia disponible y las anteriores; si no se abrió con conexión ayer, no se
simula un archivo de ayer. Conserva las siete últimas capturas diarias satisfactorias.

El visor reutiliza dashboard, personas, fichas, movimientos, miembros, cuotas e
informes de la aplicación. La copia se mantiene explícitamente seleccionada aunque
vuelva Internet, hasta pulsar «Volver a los datos actuales». Los cálculos usan el
instante copiado y las zonas de grupo originales, no cuotas nuevas de otro mes.
Auditoría, solicitudes, avisos propios y papelera se consultan como registros
guardados sin acciones de gestión, con más filas cargables desde el propio archivo.

## Fuente y consistencia

- REST Firestore bajo JWT de la cuenta actual; sin cuenta de servicio, IAM nuevo,
  sesión Supabase, claves administrativas o escrituras de servidor.
- Descubre membresías por UID y solo captura grupos activos autorizados. La misma
  fecha `readTime` gobierna documentos, consultas y páginas de doscientos registros.
- Incluye perfil propio y su auditoría; grupos, membresías, personas, movimientos,
  reglas/versiones de cuota, periodos, asignaciones, contadores de reparto,
  configuración actual de cuotas/invitación, preferencias propias y avisos propios.
  Auditoría/solicitudes generales solo para gestores autorizados en el grupo.
- No descarga globalmente `users`, Auth, archivos binarios ni colecciones privadas
  de dispositivos, entregas o estado del worker. «Completa» se refiere al conjunto
  de datos de consulta de esa cuenta, nunca a un export administrativo de Firebase.
- Se conserva el formato REST tipado: céntimos int64 exactos, timestamps originales,
  nulos y mapas. Modelos de lectura se validan antes de publicar el archivo.
- Relee membresías/accesos al terminar. Si cambian durante la descarga, no publica
  la captura. Un error no sustituye la última copia buena por resultados parciales.
- Límites de seguridad de memoria: cien mil documentos, 32 MiB por respuesta y
  96 MiB de contenido previo al cifrado; excesos fallan sin truncar. No está medida
  la fluidez física con historiales cercanos a esos límites.

## Almacenamiento y permisos

- Directorio de soporte privado de la app `bote_daily_copies_v1/{hashUID}`.
  AES-GCM de 256 bits con nonce y etiqueta de autenticidad; UID ligado mediante AAD.
  Clave por cuenta en Android Keystore/almacenamiento seguro y Keychain en iOS.
- JSON y cifrado/descifrado se procesan en isolates de Dart para apartar ese
  trabajo del hilo de la interfaz. El acceso al almacén nativo de claves permanece
  en el isolate principal.
- En iOS se usa accesibilidad solo en este dispositivo. En Android se desactiva
  Auto Backup en el manifest siguiendo los requisitos del almacenamiento seguro:
  la copia solicitada es local y no se añade sincronización de claves a Google Drive.
- Escritura temporal, relectura/autenticación y publicación antes de podar antiguos.
  Archivos temporales/corruptos no se anuncian como copias válidas. Un archivo del
  mismo día no se sobrescribe por una descarga normal posterior.
- Catálogo/carga/limpieza serializados. La generación de sesión impide que una
  descarga antigua vuelva a guardar archivos después de salir/cambiar de cuenta.
- Al confirmar acceso cambiado se bloquea el visor anterior y se retira el grupo
  afectado de las copias, conservando otros grupos de esos archivos. Si falla esa
  redacción, se intenta retirar el archivo de cuenta mediante limpieza completa.
  Si no queda ningún grupo accesible en un archivo, se elimina ese archivo.
  Un error general al consultar servidor no acredita revocación: no se presenta
  como permiso nuevo ni se transforma en una copia completa.
- Sin Internet no se puede saber si se revocó un permiso remoto. Se trata de datos
  históricos descargados por esa misma cuenta; no se promete revocación offline.
- Consulta aislada en un ProviderContainer independiente del contenedor en vivo.
  Proveedores Firebase/Auth/Supabase bloqueados, movimientos con adaptador de solo
  lectura, rutas de edición ausentes y acciones de gestión/fotos deshabilitadas.
  No recupera envíos pendientes ni modifica avisos/preferencias al abrirlos.
- La app principal puede seguir revalidando acceso y gestionando su registro de
  avisos; el visor no necesita ni utiliza respuestas actuales para sus cifras.

## Evidencia técnica

Cinco pruebas dirigidas en `test/daily_snapshots_test.dart` superadas:

1. Cifrado autenticado, poda a siete copias, aislamiento por UID, archivo corrupto,
   no sobrescritura diaria y conservación ante descarga fallida.
2. Salida durante una descarga impide su reaparición; revocación retira el grupo.
   Una cuenta sin grupos no consume su copia diaria; entrar después permite
   capturarla, y una segunda apertura no repite la descarga completa.
3. Paginación de más de doscientos movimientos bajo readTime fijo, rechazo de otra
   cuenta y de privilegios cambiados durante la captura; no admitir usuarios ajenos.
4. Mismas proyecciones de caja/cuotas con devolución parcial (saldo 85 €, pendiente
   de mes 5 €), calendario congelado, acceso a SDK y escrituras rechazados.
5. Widget: abrir un grupo muestra el dashboard habitual y aviso fijo de copia;
   no aparece «Registrar ingreso» y no se produce excepción de renderizado.

Se corrigió un bloqueo al cerrar la tarea compartida de descarga: su callback de
finalización no debe devolver su propio Future. La prueba de descarga fallida y
salida detectó ese problema antes de la entrega. Una prueba inicial de providers
también se ajustó para mantener la suscripción mientras esperaba datos.

Validación final del 23/10/2026:

- `flutter test --no-pub test/daily_snapshots_test.dart`: cinco pruebas superadas.
- `flutter analyze --no-pub`: sin incidencias.
- `flutter build apk --debug --no-pub`: compilación correcta.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- SHA256: `b191292e2ff1d9a4e2883e6b8cde771d26ac1f56ebbc56b14f1c90b83c951b26`.

No se ha instalado/ejecutado la app ni se ha usado la sesión Google de un móvil.
No se ha descargado una copia móvil real ni cambiado datos/configuración remota.

## Comprobaciones manuales y límites

Seguir COP-01–COP-10 en [GUIA_PRUEBAS_MOVILES.md](GUIA_PRUEBAS_MOVILES.md).
Probar almacenamiento seguro y persistencia después de cerrar proceso, avión,
recuperar conexión, otro día y otro móvil. Cada teléfono necesita su propia primera
descarga; no basta copiar el APK ni abrir la cuenta en otro dispositivo.

- No todas las fotos estarán disponibles ni serán de la misma fecha que los datos.
- Una caché puede ser más reciente que la copia; no se impone la copia como mejor.
- No se crean archivos de días en los que la app no se abrió con Internet.
- Cerrar sesión retira las copias de esa cuenta en ese móvil; desinstalar/borrar
  datos puede eliminar ficheros y claves. No sustituye un respaldo externo recuperable.
- Sin sesión local restaurada no se realiza un login Google nuevo sin Internet.
- Un fallo en Rules/API que impida comprobar el acceso no demuestra revocación;
  una copia antigua nunca se usa para conceder permisos de escritura.
- Sigue pendiente prueba real iOS/Mac de Keychain, firma y plataforma.
- No hay cambios nuevos de Rules, índices, colecciones, Supabase o facturación.
