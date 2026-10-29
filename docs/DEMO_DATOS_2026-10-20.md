# Datos DEMO después del reinicio — 20/10/2026

Reinicio autorizado ejecutado a las **16:12 UTC**. Se eliminaron **63 documentos
Firestore y 3 fotos Supabase**. No se borraron cuentas Firebase Authentication,
proyectos, bucket, índices, secretos, claves, configuración de servicios o Hosting.
El cron se pausó durante el mantenimiento y quedó reactivado cada quince minutos.

Se sembraron **1.254 documentos** y se releían todos sus campos antes de dar por
terminada la operación. El worker creó después su documento técnico de estado en
cada grupo. No hay notificaciones históricas ni dispositivos push sembrados.
Las fotos iniciales son iniciales/fallback: no se reutilizan fotos anteriores.

Propietaria real de ambos: **ale.manu.cristi@gmail.com**,
UID `JDQpjp5XtFTDOoVgK5Rbc9EGUHB2`. Es la única membresía de cada grupo al comenzar;
las demás personas son internas, sin cuenta. Para probar otros roles debes entrar
con Google real desde M2/M3 y usar las invitaciones. No hay usuarios falsos de Auth.

## Inventario inicial

| Concepto | Comunidad San José | Jóvenes y proyectos |
| --- | --- | --- |
| Nombre visible | [DEMO] Comunidad San José | [DEMO] Jóvenes y proyectos |
| ID | demo-comunidad-20261020 | demo-jovenes-20261020 |
| Moneda / zona | EUR / Europe/Madrid | EUR / Europe/Madrid |
| Personas visibles | 12: 11 activas, 1 inactiva | 8: 7 activas, 1 inactiva |
| Personas adicionales en papelera | 2 | 2 |
| Movimientos, todos los estados | 159 | 121 |
| Asignaciones | 114 | 76 |
| Ingresos activos | 2.537,50 € | 1.047,50 € |
| Retiradas activas | 339,80 € | 339,80 € |
| **Saldo** | **2.197,70 €** | **707,70 €** |
| Invitación a usuario nuevo | Aprobación | Entrada automática como member |

Los códigos son aleatorios y se consultan/comparten desde la app. No se guardan en
esta documentación. Las cuentas que salgan y vuelvan requieren aprobación siempre.
Todos los nombres, notas y conceptos de personas de ejemplo están identificados DEMO;
el propietario conserva su nombre real para reconocer su vínculo.

## Cuotas: referencia del 20 de octubre de 2026

Se usa el estado actual de ingresos/devoluciones, no una reconstrucción al cierre.
Cada importe de esta tabla se ha calculado con `QuotaReportRepository` de la app.

| Concepto | Comunidad | Jóvenes |
| --- | --- | --- |
| Cuota mensual actual | 25,00 € | 15,00 € |
| Esperado enero–octubre | 2.445,00 € | 900,00 € |
| Pagado asignado enero–octubre | 2.371,50 € | 881,50 € |
| Pendiente enero–octubre | 157,50 € | 97,50 € |
| Cumplimiento enero–octubre | 93,55 % | 89,16 % |
| Sobrepagos enero–octubre | 84,00 € | 79,00 € |
| Esperado octubre | 275,00 € | 105,00 € |
| Pagado octubre | 227,50 € | 77,50 € |
| **Pendiente octubre** | **62,50 €** | **37,50 €** |
| Crédito sin asignar | 85,00 € | 115,00 € |
| Pagado asignado a meses futuros | 55,00 € | 25,00 € |

Sobrepagos no compensan otros meses/personas: por eso el pendiente no equivale
simplemente a esperado menos pagado. Crédito libre aumenta caja, no cuotas pagadas.
Comunidad tiene cuota de 20 € desde enero, 25 € desde agosto y 30 € programados
desde noviembre; Jóvenes, 10 € desde enero y 15 € desde julio.

## Casos incluidos

- Marta: septiembre/octubre sin pagar; Luis: octubre parcial; Pablo: pendientes
  desde julio; Lucía: ingreso con crédito sin asignar; Javier: inactivo y periodo
  cerrado hasta junio. Otras personas tienen pagos completos o sobrepago manual.
- Propietario vinculado a `owner`, adelanto de noviembre/diciembre y crédito.
- `refund-origin`: ingreso de Carmen repartido en cuatro meses; devolución parcial
  de esos cuatro meses y de crédito libre. También devolución anulada y corregida
  con sustituto. Los contadores reflejan solo las devoluciones activas.
- `refund-advance`: devolución parcial de noviembre y crédito del adelanto.
- `cancelled-income`: ingreso anulado, conservado sin sumar al saldo.
- `corrected-expense` y `replacement-expense`: retirada original corregida de
  12 € a 9 €, conservando vínculo y motivo.
- Cuarenta retiradas generales por grupo a lo largo de enero–octubre.
- Papelera: `trash-restorable`, enviada el 19/10; `trash-expired`, enviada el 1/10.
  Ambas sin historial, participación ni vínculo. Restaurar la primera introduce
  deliberadamente una persona sin cuota configurada hasta que elijas su periodo.
- Auditoría suficiente para paginar, incluyendo personas, cuotas, asignaciones,
  movimientos y devoluciones. Son fixtures ficticios, no acciones reales de otros
  usuarios ni evidencia física de permisos multiusuario.

Preferencias push de la propietaria inicialmente desactivadas en los tres tipos;
la bandeja está vacía y no se ha sembrado ningún token de dispositivo. Activa las
preferencias y el botón de avisos del móvil cuando hagas su recorrido manual.

## Evidencia y recuperación

- Generador: `tools/demo_dataset.cjs`; validador real Dart:
  `tools/validate_demo_dataset.dart`. No ejecutarlos para resembra automática.
- SHA-256 del dataset sembrado:
  `9cd46e1bff408a7b7f5ac071aa5e44b08af3c5068e8ffddfa5904a2885e7bca6`.
- Lectura posterior de los 1.254 documentos conforme al plan. Ocho agregados de
  caja remotos coinciden con movimientos bajo una instantánea coherente.
- Worker autenticado: HTTP 200, dos grupos procesados, cero fallos. No acredita
  entrega push ni ejecución del recordatorio en un teléfono.
- Copias y restauración: [RECUPERACION_DATOS_2026-10-20.md](RECUPERACION_DATOS_2026-10-20.md).
- Recorrido físico: [GUIA_PRUEBAS_MOVILES.md](GUIA_PRUEBAS_MOVILES.md).

Las cifras cambian al operar o al cambiar el mes. Antes de probar anotarlas;
para recorridos con cantidades exactas desde cero usa los grupos nuevos G/H de
la guía. No volver a reiniciar toda la base sin nueva autorización.
