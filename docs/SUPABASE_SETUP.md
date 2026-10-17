# Fotos con Supabase — preparación

Actualizado el 2026-10-15.

## Acuerdos y configuración conocida

El usuario elige Supabase Storage para fotos, manteniendo Firebase Authentication
con Google y Firestore para los datos. Sustituye el aplazamiento de la integración
de almacenamiento de D052. Función desplegada y pantallas conectadas; validación
del guardado real confirmada parcialmente: el usuario ve fotos de personas y su
foto de cuenta. Corrección de foto predeterminada, caché y editor instalados;
el usuario confirma también en A059P foto en Miembros, ausencia de parpadeo y
funcionamiento del editor de recorte/zoom/rotación (2026-10-15).

- Proyecto Supabase creado por el usuario.
- Integración Third-Party Auth con Firebase `boteparroquial` confirmada por el usuario.
- URL proporcionada: `https://ietnizafvtovelyuxbvk.supabase.co`.
- Clave **publishable** proporcionada, configurada en `SupabaseConfig`.
- No se ha solicitado ni incorporado contraseña, clave secret o service_role.
- Región comprobada mediante Management API: `eu-west-1` (Irlanda), no Madrid.

## Implementación local

SDK Dart `supabase` (sin un segundo sistema de sesión de Flutter), conexión
diferida mediante `supabaseConnectionProvider` y adaptador en services. Obtiene
el token de la cuenta Firebase actual en cada petición; sin sesión rechaza el
acceso en lugar de usar acceso anónimo. No solicita ni modifica custom claims.
Las pantallas consumen photos/providers → PhotoRepository → PhotoService/
SupabasePhotoService y PhotoPickerService/DevicePhotoPickerService. No hay nuevas
reglas/campos Firestore: las fotos usan rutas deterministas dentro del bucket.
El cliente no puede asignar rutas ni roles; añade el UID de la sesión que originó
la acción y el servidor lo compara con el JWT para impedir envíos bajo otra cuenta.

La cámara y la galería se habilitan por elección del usuario. Vista previa y
guardado explícito, cambio y retirada con confirmación, con iniciales al faltar foto.
Editor accesible desde «Mi foto de cuenta» y tocando las imágenes de grupo,
miembros o personas. Una persona nueva debe guardarse antes de añadirle la foto.
Las fotos también se muestran en tarjetas de inicio, resumen e historial.

Preparación de imagen fuera del hilo de UI: orientación, JPEG con lado mayor
1024 px, sin EXIF/GPS del original, máximo 512 KiB. Errores y cancelación no
reemplazan automáticamente una foto; las operaciones requieren conexión.
Los borradores se invalidan al cambiar sesión/acceso. Caché privada por cuenta en
memoria (20 MiB, hasta 256 entradas) y directorio temporal de la app (40 MiB,
hasta 256 archivos por cuenta); el SO puede eliminarla. Se purga al cerrar sesión
y se invalida la de grupos cuya revocación se observa. Los permisos no derivan de
la caché: la UI exige sesión/grupo activo y el backend autoriza cada consulta.
Una descarga anterior al logout no puede repoblar la caché tras su limpieza.

Al navegar, los bytes ya cargados se presentan sin esperar otra petición. Las
lecturas usan una frescura de un minuto; al vencer se revalidan en segundo plano,
manteniendo la foto mientras se consulta la versión. Reanudar/actualizar fuerza la
revalidación. `readCached` evita devolver los bytes si ETag/versión no ha cambiado.
Sin caché, se usa un espacio neutro durante la primera carga, no iniciales
provisionales. Iniciales al confirmar que no hay foto o ante un error sin imagen.
No se promete sincronización instantánea entre móviles ni caché offline perpetua.
Si Android termina el proceso durante cámara/galería, se descarta el resultado
sin contexto y se debe volver a elegir; no se adjunta a otra cuenta/destino.
Info.plist declara uso de cámara y galería para iOS, sin compilación en Mac.
Galería y cámara abren el editor nativo encapsulado por AppImageCropper: recorte
cuadrado, desplazamiento, zoom y rotación. Cancelar conserva la foto/borrador
anterior; aceptar vuelve a la vista previa y aún requiere Guardar foto.

Mantener UI → Provider → Repository → Service → SDK. La configuración y el
cliente son infraestructura; no importar el SDK Supabase en widgets ni modelos.

## Arquitectura elegida y permisos

Supabase no conoce las membresías/roles de Firestore. No conceder permisos usando
un rol enviado por Flutter. D053 sigue definiendo quién puede cambiar cada foto.

El usuario elige **Supabase Edge Function**, sin replicar membresías en SQL.
`supabase/functions/photo-access/` verifica el JWT Firebase con las claves
públicas de Google: firma RS256, emisor/proyecto, audiencia, caducidad, UID y
fechas de autenticación/emisión. Consulta Firestore REST con el token del usuario:
Security Rules siguen aplicándose, sin clave privada ni Admin SDK de Firebase.
No se cachean roles. La comprobación JWT no consulta revocación global de tokens;
la membresía/grupo se relee por operación y la caducidad JWT sigue vigente.

Acuerdo confirmado por el usuario:

- Foto de cuenta: solo la edita su dueño; sirve por defecto dentro de los grupos.
- Fotos del grupo y sus miembros: lectura dentro del grupo por miembros activos.
- Miembro cambia su propia foto; admin autorizado cambia miembros normales;
  owner puede cambiar también administradores. Solo owner cambia la portada.
- Si no existe foto específica de miembro, el servidor devuelve su foto de cuenta
  tras autorizar al lector dentro de ese grupo. Cambiar una foto de miembro solo
  afecta a ese grupo. «Usar foto de cuenta» elimina la excepción del grupo.
- Persona interna: foto independiente, sin sincronización con cuenta/membresía;
  owner o admin autorizado la cambia. La inactividad de la persona no borra su foto.
- Admin autorizado conserva el requisito existente de persona vinculada activa.
- Las fotos son privadas: sin URLs públicas ni enlaces firmados reutilizables.
  Lectura mediante la función, que vuelve a autorizar. Una imagen ya descargada
  no puede revocarse del dispositivo que la recibió.

El backend exige que la membresía destino esté activa para fotos de miembros.
Las cuentas/grupos/personas sin imagen conservan el fallback a iniciales en UI.

La integración directa Firebase → Storage descrita en la documentación oficial
requiere el custom claim `role: authenticated`; Firebase no lo añade por defecto.
No confundirlo con los roles owner/admin/member. No añadir ese claim ni Functions
de Firebase. Esta implementación no usa acceso cliente directo a Storage y no
necesita ese claim. Edge Functions de Supabase son otra plataforma: no se ha
activado Blaze ni desplegado Cloud Functions de Firebase.

## Contrato de la función

`POST /functions/v1/photo-access`, Authorization Bearer con ID token **Firebase**.
JSON: `{"action":"access","actorUid":"...","target":{"kind":"group","groupId":"..."}}`.

Acciones: `access` devuelve `canRead/canEdit`; `read` devuelve bytes como
`application/octet-stream` para el SDK Dart (sin caché y con nosniff);
`readCached` admite `ifNoneMatch` y devuelve JSON con versión y base64 únicamente
cuando hace falta, o `notModified: true` sin imagen. Todos vuelven a autorizar
antes de leer o responder «sin cambios». El read binario anterior se conserva
para APK previos. La versión distingue foto de cuenta y excepción de grupo.
`upload` añade `imageBase64`; `remove` quita únicamente esa foto. El resultado de
`access` es informativo: cada lectura/escritura vuelve a comprobar permisos.

Destinos: `account` + `uid`, `group` + `groupId`, `member` + `groupId/uid`,
`person` + `groupId/personId`. Rutas calculadas en servidor, sin aceptar URLs,
rutas, roles ni nombres de archivo del cliente. Una imagen por destino, sin
modificar ni borrar documentos de personas o movimientos.

Bucket privado `boteparroquial-photos`, máximo 512 KiB por archivo; JPEG/PNG/WebP.
Se comprueba firma de formato, no decodificación completa de la imagen. El cliente
deberá reducir/comprimir antes de enviar; no se aceptan SVG ni Content-Type arbitrario.
Respuestas sin caché HTTP, sin tokens/perfiles en logs y con errores genéricos.

`verify_jwt = false` desactiva exclusivamente la verificación legacy de Supabase;
la función exige y verifica el JWT de Firebase por sí misma. No eliminar esa
verificación. Credencial de Storage exclusivamente en el entorno de la función
(`SUPABASE_SERVICE_ROLE_KEY` estándar); nunca en Flutter o Git.

Migración `supabase/migrations/20261015000100_private_photos.sql` prepara el bucket.
No añade políticas cliente. Antes de habilitarlo, revisar que no existan políticas
globales permisivas de Storage que permitan saltarse la función. Un bucket existente
con configuración diferente detiene la migración en vez de sobrescribirlo.

## Despliegue y siguientes pasos

Login de CLI completado por el usuario y acceso confirmado mediante `projects list`.
Función `photo-access` desplegada mediante `functions deploy --use-api` en el
proyecto `ietnizafvtovelyuxbvk`; versión 3, ID `efe04baa-c164-4a4d-8352-c8748a4bc61d`.
La API de administración permite SQL con `db query --linked --project-ref ...`,
sin pedir contraseña ni conectar GitHub. Se aplicó el contenido de la migración
con `--file`; esto no registra por sí solo una migración en el ledger de `db push`.
El SQL es idempotente respecto a un bucket ya creado con la configuración prevista.

Comprobado en remoto: bucket privado, límite 524288, formatos JPEG/PNG/WebP;
RLS activada en storage.objects y ninguna política cliente en esa tabla.
Peticiones a la función sin token o con token falso devuelven 401. La primera
sonda devolvió un error transitorio no JSON; tras el despliegue actualizado se
obtuvieron ambos rechazos esperados. No se atribuye una causa no comprobada.

APK compilado, instalado con `install -r` en A059P y proceso arrancado (PID 32723).
El selector de fotos de Android aparece en la pantalla; no se manipula la galería
personal del usuario. Sin errores flutter:E/AndroidRuntime:E en la consulta del
proceso realizada. Se pide al usuario elegir y guardar una foto para confirmar
el flujo real. No darlo por superado solo por el despliegue o la compilación.

El usuario confirma guardado/lectura de fotos de personas y foto propia de cuenta.
La ausencia de esa foto en Miembros se debía a la independencia sin fallback del
primer diseño. Se acuerda foto de cuenta por defecto, con excepción por grupo.

Actualización: APK con caché y image_cropper compilado e instalado de nuevo con
`install -r`; se envía orden de arranque. El usuario confirma expresamente:
«Se ve en Miembros, sin parpadeo y el editor funciona». Se registra como validación
física de esos tres puntos en A059P, sin extenderla a otros roles o dispositivos.

Pendientes: comprobar separadamente cámara frente a galería, retirada,
permisos con otros roles/cuentas reales, sincronización entre móviles e iOS.
No confundir las simulaciones con esas comprobaciones.

## Validación

`dart format` de los tres archivos nuevos y `flutter analyze --no-pub` completados
sin incidencias. `git diff --check` limpio. No se repiten suites ni se compila un
APK durante aquella preparación inicial, que no cambiaba flujos visibles ni añadía
plugins nativos. La integración posterior sí añade image_picker y se compila.
En esta ampliación: Deno 2.9.6, `deno fmt`, `deno check` del entrypoint y tests;
cinco pruebas dirigidas superadas (JWT firmado localmente y rechazos de firma,
proyecto/caducidad/fechas; matriz de roles; aislamiento y entradas no válidas;
revocación de permisos entre operaciones, formatos/límite de tamaño; personas y
admin inactivo). Dependencias remotas simuladas; no acreditan reglas SQL ni red real.
Ampliación actual: cinco pruebas Deno superadas tras vincular actorUid y ajustar
la respuesta binaria para Flutter. Doce casos Flutter dirigidos: cuatro de fotos,
cuatro de auth y cuatro de grupos. La primera ejecución pasó once y tuvo un timeout
en el simulador de sesión; corregido el stream del test, se repitió solo ese caso
y pasó. No se ejecutó la suite completa. Casos de fotos: aislamiento/denegación,
preparación sin metadatos, cancelación/vista previa/guardar/quitar y cambio de cuenta
durante selección sin recuperar el borrador o error anterior.
`flutter analyze --no-pub` sin incidencias y APK debug compilado. Evidencia remota
y comprobaciones nativas detalladas arriba. El usuario confirma después personas
y cuenta propia; no equivale a validar otros roles ni ambas fuentes de imagen.

Validación de la corrección de caché/editor: siete pruebas de fotos superadas
(incluyen disco/memoria, respuesta sin cambios sin sustituir bytes, borrado por
cuenta y descarga tardía tras logout, y remonte/revalidación sin perder imagen),
un flujo oscuro existente de grupos para fallos aislados de infraestructura de fotos,
y seis pruebas Deno (nuevo fallback/condicionales, con denegación tras revocar acceso).
Análisis limpio, APK debug compilado e instalado; función versión 3 ACTIVE y dos
sondas reales 401 sin sesión/token falso. Sin suites completas ni segunda cuenta.
No se reanudan las pruebas aplazadas de otra cuenta o varios móviles.

## Mejora del 2026-10-16 — editar la imagen guardada

«Editar foto actual» abre el mismo editor nativo usando la imagen mostrada o su
borrador, sin borrarla ni volver a elegirla de la galería. PhotoController →
PhotoRepository.editCurrent → PhotoPickerService.edit. Se mantienen la validación
de destino y permisos, la protección por sesión y el guardado explícito posterior.
Cancelar deja la foto y el borrador anteriores. El input temporal privado se
elimina al cerrar el editor; no se borra ninguna fuente de la galería.
Se edita la versión guardada/recortada; no se conserva un original sin recortar.

Comprobación dirigida del flujo de selección/edición, cancelar, guardar y retirar
superada con servicios simulados. Sin cambio ni despliegue de la función remota.
El usuario ejecutará la app: no se instala ni arranca en esta tanda; comprobación
nativa del botón nuevo pendiente, sin extender la confirmación del editor anterior.

## Referencias

- https://supabase.com/docs/guides/auth/third-party/firebase-auth
- https://supabase.com/docs/guides/storage/security/access-control
- https://supabase.com/docs/guides/getting-started/api-keys
