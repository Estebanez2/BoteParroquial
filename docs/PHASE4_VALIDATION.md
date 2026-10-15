# Phase 4 — Movimientos

Implementada el 2026-10-15. Comprobaciones dirigidas, por preferencia del usuario:
cuatro pruebas de Rules, una del flujo visual y una comprobación nativa contra
Firestore real con la sesión existente. No se ha repetido la suite completa.

## Resultado

- Ingresos por persona; retiradas generales o por persona; céntimos enteros positivos.
- Pantallas completas elegidas por el usuario. Personas inactivas permitidas con aviso.
- Fechas efectivas de hoy o anteriores; descripción/motivos y autores registrados.
- Historial en tiempo real, fecha efectiva y de registro separadas, estados y enlaces
  para consultar original y sustituto. Sin editar importes históricos ni borrar.
- Anulación con motivo/autor/fecha. Corrección atómica con nuevo sustituto; también
  permite cambiar ingreso/retirada por elección del usuario.
- Aviso y confirmación adicional si la operación deja saldo negativo, incluidos
  correcciones y anulaciones. El saldo se deriva, no se almacena como cifra editable.
- Reintento con el mismo ID y datos no crea otro documento. Los conflictos de versión
  o datos distintos se rechazan. Se conserva toda cadena de correcciones.

## Evidencia

| Comprobación | Resultado |
| --- | --- |
| Formato / `flutter analyze --no-pub` | Sin incidencias |
| `flutter test --no-pub test/movements_test.dart` | Una prueba del flujo financiero superada |
| `movements_rules.test.cjs` en emulador | Cuatro pruebas superadas |
| Android SDK contra Firestore real | PHASE4_SMOKE_PASS, sin duplicados al reintentar |
| APK normal `lib/main.dart` | Compilado, instalado e iniciado en A059P |
| Reglas publicadas | Coinciden con firestore.rules local; índice de membresías sigue READY |
| Verificación de datos real | Importes enteros y enlaces de corrección recíprocos |

Las cuatro pruebas de Rules cubren roles/permisos, persona de otro grupo o ausente,
tipos/autores/fechas, importes cero/negativos/decimales, modificación histórica y borrado,
corrección parcial o duplicada, cadena de correcciones, estados terminales y dos
correcciones concurrentes sobre el mismo original (solo una consigue escribir).

La prueba de pantalla comprueba entrada 20,50 €, persona requerida, aviso de inactiva,
saldo negativo y cancelación de ese aviso sin escribir, corrección conservando importe
original y anulación. Solo active contribuye al cálculo del resultado esperado.

La herramienta optativa `tool/movement_smoke.dart` se ejecutó una vez en debug en
A059P (Android 16/API 36), usando Firebase Auth y Firestore reales, sin credenciales
administrativas dentro de Flutter. Creó/reintentó el mismo ingreso, corrigió/reintentó,
anuló/reintentó, registró/anuló una retirada general y registró para persona inactiva.
Resultado capturado: 4 documentos nativos, saldo previo 5800 y final 7050 céntimos.
Los reintentos no añadieron documentos. Esos movimientos DEMO quedan conservados.
No se tomó esta ejecución como prueba de las comprobaciones aplazadas de auth.

Después se recompiló e instaló el entrypoint normal. La herramienta no está conectada
a rutas de producción y no ejecuta comprobaciones al abrir la app habitual.
El ajuste final de fechas se verificó con el flujo y las reglas dirigidas; no se
repitió toda la comprobación nativa después de ese ajuste de validación.

## Datos DEMO autorizados

No se borraron ni sobrescribieron los datos existentes. Se crearon 17 documentos
mediante la herramienta de fixtures y 4 movimientos desde el SDK Android.

| Grupo | Movimientos | Activos / anulados / corregidos | Saldo observado |
| --- | --- | --- | --- |
| Prueba1 | 11 | 6 / 3 / 2 | 70,50 € |
| Prueba · Saldo negativo | 2 | 2 / 0 / 0 | −15,00 € |
| Prueba · Historial vacío | 0 | 0 / 0 / 0 | 0,00 € |

Prueba1: `786e41f1-7f03-48a5-b29a-db966b67cd56`.
Negativo: `demo4-786e41f1-7f03-48a5-b29a-db966b67cd56-negative`.
Vacío: `demo4-786e41f1-7f03-48a5-b29a-db966b67cd56-empty`.
Personas `[Prueba] Ana`, `[Prueba] Luis`, `[Prueba] Marta (inactiva)` en Prueba1;
otra `[Prueba] Ana` dentro del grupo negativo. No se crean cuentas Google ficticias.
Movimientos sembrados con IDs demo4-* y nativos con native4-*; descripciones DEMO.
Las cifras son el estado observado tras las comprobaciones, no constantes de la app.

```powershell
# Vista previa, sin escrituras.
node tools/seed_phase4.cjs --group ID_DEL_GRUPO
# Crear solo documentos que falten, con autorización del usuario.
node tools/seed_phase4.cjs --group ID_DEL_GRUPO --apply
# Consultar saldos y comprobar enlaces, sin escrituras.
node tools/seed_phase4.cjs --group ID_DEL_GRUPO --verify
```

La siembra usa los permisos del operador Firebase CLI y no prueba Security Rules.
La comprobación nativa sí usa el SDK cliente y las reglas de la cuenta autenticada.
La herramienta Node depende de Firebase CLI instalado, como bootstrap_group.cjs.
Los reportes se guardan fuera de Git en .dart_tool/phase4-fixtures.json y
.dart_tool/phase4-native-result.log. El usuario indica que él borrará los datos al
empezar el uso real; no se ejecuta ningún reset en esta fase.

Ruleset final publicado: `89e8c7fc-2898-4366-a310-139a8a2b26f7`. Sin índices nuevos.
Referencia de [validación de operaciones atómicas con getAfter](https://firebase.google.com/docs/firestore/manage-data/transactions).

## Límites y siguientes fases

- El aviso de saldo usa una consulta fresca al servidor; no reserva saldo frente
  a operaciones concurrentes entre revisión y escritura. Negativo está permitido.
- El ID se mantiene mientras existe el formulario. Tras cerrar/reabrir la app,
  revisar historial ante resultados inciertos antes de iniciar un envío nuevo.
  Actualización Phase 6: ahora se persiste el intento por UID/grupo antes de enviar,
  se consulta su resultado al abrir el grupo y se recupera el mismo ID/datos.
- «Hoy» usa el calendario del dispositivo; Rules añade un margen técnico de 24 h
  para fechas civiles UTC. La validación exacta por reloj/zona del grupo en servidor
  y la política offline quedan para hardening. Transacciones requieren conexión.
  Actualización Phase 6: la app usa la zona IANA del grupo y se permite consulta
  de caché señalizada; operaciones económicas requieren servidor. El margen de Rules
  permanece y la comprobación IANA exacta en servidor sigue pendiente.
- No se ha probado sincronización en dos móviles ni una segunda cuenta real.
  Las pruebas manuales aplazadas de Phase 1 siguen pendientes.
- La degradación persistida del rol admin continúa en Phase 7; Rules sí exige
  persona vinculada activa para que un admin escriba datos económicos.
- No se han ejecutado suites previas completas ni nuevas matrices visuales.
  iOS no se ha compilado/probado desde Windows.
- Dashboard/saldo visible y estadísticas básicas pertenecen a Phase 5; cuotas,
  allocations, notificaciones y auditoría avanzada no se implementan aquí.
