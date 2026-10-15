# Phase 2 — Groups & Membership

Estado: implementada y validada en su alcance inicial el 2026-10-15.
Prueba1 visible en A059P; acceso como propietario y lista de miembros comprobados.
El aislamiento entre cuentas/grupos y la revocación se comprueban con emulador
y repositorios simulados, no con una segunda cuenta real.

## Alcance y decisiones confirmadas

- El usuario elige seguir el roadmap: primer grupo desde terminal; creación libre,
  invitaciones, edición de roles y transferencia permanecen en Phase 7.
- Grupo **Prueba1**, con la cuenta actual de la app confirmada como propietaria.
  La cuenta del operador Firebase CLI es distinta: no se eligió como owner.
- El usuario elige añadir uid y displayName a cada membresía para descubrir
  grupos propios y mostrar nombres sin publicar perfiles globales.
- Se utiliza el sistema visual existente, temas claro/oscuro y AppReveal con
  movimiento reducido. Login conserva su composición anterior con el tema común.
- No se crea una segunda cuenta, un segundo administrador ni personas ficticias.
  El owner todavía no tiene persona interna vinculada; Persons comienza en Phase 3.

## Implementación

- Group y GroupMember son modelos sin Flutter/Firebase.
- GroupService encapsula consultas y serialización; GroupRepository filtra
  membresías activas de la cuenta solicitada.
- Providers de membresías, grupo y miembros, con reintentos explícitos.
- Lista de grupos propios en home; contexto explícito `/groups/:groupId`.
- Lecturas en tiempo real y estados de carga, error, sin grupos y sin acceso.
- No se conserva un singleton con un grupo fijo. Cambiar cuenta o revocar acceso
  descarta la presentación anterior; no se muestra durante carga/error.
- Reglas: solo miembros activos con rol válido leen grupos activos y sus miembros.
  La búsqueda collection-group de membresías exige filtrar el uid propio.
  Leer una membresía propia inactiva no autoriza a leer su grupo.
- Todas las escrituras cliente de grupos/membresías siguen denegadas, incluso
  para owner. Personas, movimientos y colecciones futuras permanecen cerrados.

## Evidencia automática

| Comprobación | Resultado |
| --- | --- |
| `dart format lib test` | Correcto |
| `flutter analyze --no-pub` | Sin incidencias |
| `flutter test --no-pub` | 26 pruebas superadas; dos exportaciones visuales optativas omitidas |
| Emulador Firestore | 9 pruebas superadas: 4 de perfil y 5 de grupos |
| `flutter build apk --debug --no-pub` | APK generado |
| Exportación de vistas de grupos | Tres capturas con fuentes reales, revisadas visualmente |
| Herramienta de aprovisionamiento | Vista previa, commit atómico y repetición sin duplicar comprobados |
| Backend real | Reglas coinciden con el fichero local; índice READY; único owner |

Las pruebas de grupos cubren dos grupos, rutas ajenas, revocación, cambio de
cuenta con datos previos cargados, error/reintento y 360 px con texto al 160 %,
modo claro/oscuro y movimiento reducido. Las reglas prueban owner/admin/member,
anónimos, no miembros, membresías inactivas y grupos cerrados; rechazan
autopromoción, modificación del propietario, escritura/borrado y acceso económico.

Comando de reglas desde la raíz (Java 21 en PATH):

```powershell
firebase.cmd emulators:exec --only firestore --project demo-boteparroquial 'node --test tools/firestore-rules/profile_rules.test.cjs tools/firestore-rules/groups_rules.test.cjs'
```

Exportación optativa, sin datos reales:

```powershell
flutter test --dart-define=EXPORT_GROUP_PREVIEWS=true test/groups_preview_test.dart
```

Capturas ignoradas por Git en `.dart_tool/groups_preview/`.

## Firestore real

Proyecto `boteparroquial`, base `(default)`, Madrid `europe-southwest1`.
Ruleset publicado: `dd2fe98e-7d08-4003-996e-ebf411ed4672`.
Índice `members.uid` ASCENDING, ámbito COLLECTION_GROUP, comprobado READY.
No existían índices personalizados previos. No se cambiaron las reglas de perfiles.

Prueba1: `786e41f1-7f03-48a5-b29a-db966b67cd56`, moneda EUR, zona Europe/Madrid.
Commit del servidor: `2026-10-15T11:25:07.456Z`, grupo y membresía creados juntos.
Un miembro, un owner; createdBy coincide con su uid.
Este ID es evidencia de aprovisionamiento, nunca una constante de la app.

## Dispositivo

A059P, Android 16/API 36, serial `00166155L000316`.

- APK instalado; motor Flutter y servicio de depuración arrancados.
- Usuario confirma Prueba1 en «Tus espacios».
- Árbol accesible de la app muestra «Tu espacio», «Prueba1», «Propietario», EUR,
  Europe/Madrid y su nombre con «Propietario / Activo / Tú» en la lista de miembros.
- Ajuste final de presentación aplicado mediante hot reload sin cerrar la sesión.
- Después, con la app en segundo plano, aparecieron avisos transitorios de DNS
  (UNAVAILABLE al resolver firestore.googleapis.com). No se han validado recuperación
  de red ni funcionamiento offline. Las capturas revisadas son las simuladas; la
  evidencia nativa del contenido es el árbol accesible y la confirmación del usuario.
- La segunda cuenta y la restauración de sesión de Phase 1 siguen pendientes;
  no se ha reanudado ni dado por superado ese protocolo de prueba.
- iOS no compilado ni probado desde Windows; requiere Mac y Xcode.

## Aprovisionamiento controlado

`tools/bootstrap_group.cjs` usa el login existente del operador Firebase CLI,
no credenciales de la app, archivos de service account ni claves nuevas.
Depende de los módulos internos de Firebase CLI 15.33.0 instalado en Windows;
no es una dependencia de producción. Si cambia su instalación, puede indicarse
la carpeta lib mediante FIREBASE_TOOLS_LIB. Revalidar al actualizar CLI.
Las credenciales del operador no se incluyen en Flutter ni conceden acceso global
a ningún usuario de la app. Las herramientas administrativas no sustituyen pruebas
de reglas: usan permisos IAM del operador.

```powershell
# Consultar perfiles para identificar la cuenta; no concede permisos.
node tools/bootstrap_group.cjs --list-profiles

# Vista previa sin escrituras, con UID previamente confirmado.
node tools/bootstrap_group.cjs --name NOMBRE --owner-uid UID_CONFIRMADO

# Escribir solo después de decidir nombre y propietario con el usuario.
node tools/bootstrap_group.cjs --name NOMBRE --owner-uid UID_CONFIRMADO --apply
```

Si se omite owner-uid, exige un único perfil de la app con el correo del operador.
No asume que ambas cuentas sean iguales. Un grupo existente del mismo nombre y
creador se verifica sin sobrescribirlo. Grupo/owner nuevos usan precondición de
inexistencia y timestamps de servidor en un único commit. El contrato de campos
está en FIREBASE_SCHEMA.md. La gestión completa de miembros permanece pendiente.

Referencia de la consulta: [seguridad de collection-group queries](https://firebase.google.com/docs/firestore/security/rules-query).
