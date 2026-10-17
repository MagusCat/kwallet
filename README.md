# kwall

Finanzas personales, notas y hábitos en Flutter, con datos locales en SQLite.

- Presupuesto ajustable por día/semana/mes, o adaptado al saldo libre protegiendo reservas y compromisos.
- Cuentas con mínimos y anillos; gastos por lote y registro en distintos días.
- Historial completo con filtros, búsqueda, paginación estable y resúmenes mensuales SQL.
- Calendario de pagos recurrentes y días especiales; rangos elegidos sobre el propio calendario.
- Notas libres, listas, hábitos diarios, rachas, ánimo y motivo de los días difíciles. Se pueden marcar varios días de un hábito o todos los pendientes del día en una transacción.
- Inicio con cuentas, notas y hábitos; listas que se pueden marcar sin salir del inicio.
- Bienvenida inicial y carga durante la apertura de datos, con recuperación ante fallos.
- Mascota con siete estados de animación del atlas `cat.png`, tres aspectos y opción de imagen propia; XP y reacciones al completar acciones.
- Paletas Bosque/Ciruela/Rosa/Miel, sin azul; modos claro/oscuro/sistema.
- Moneda personalizada y espejo con tasa manual.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

## Integridad y respaldo

La versión de app es 1.1.0+2; el esquema SQLite es v4. Las migraciones son incrementales y conservan datos. Antes de actualizar el esquema o restaurar, se escribe una copia JSON local de recuperación, accesible desde Ajustes.

Ajustes permite exportar/importar un archivo JSON con todas las tablas administradas: cuentas, categorías, movimientos, anulaciones, presupuestos, perfil del gato, compromisos, preferencias, asignaciones, notas, hábitos, registros diarios y recompensas. Los respaldos actuales incluyen checksum SHA-256. La importación acepta respaldos antiguos de kwall, valida estructura/referencias/saldos, rechaza versiones futuras y reemplaza los datos en una sola transacción con rollback ante fallos. El checksum detecta alteraciones; el respaldo no está cifrado. Las imágenes propias de la mascota se guardan en preferencias como contenido portable, sin depender de una ruta del dispositivo. Se aceptan imágenes fijas PNG/JPG/WebP de hasta 4 MB y 2048 × 2048.

Anular un movimiento revierte su efecto y lo conserva en el archivo de anulaciones. Archivar una cuenta conserva su historial. Las comprobaciones internas comparan el saldo inicial más los movimientos activos; no se exponen como un botón en Ajustes. Los totales incluyen todos los registros del rango, no solamente la página visible. Las instalaciones nuevas no incluyen dinero ni movimientos ficticios.

Los importes usan una unidad principal común; cambiar su símbolo no convierte los saldos existentes. La tasa espejo es manual. Las alertas de compromisos son dentro de la app.

Las capturas con datos sintéticos se generan con `flutter test --dart-define=KWALL_CAPTURE=true` en `.impeccable/review/`. Son renders de widgets; el rendimiento en Android real requiere comprobación en un dispositivo. Las capturas existentes preceden a la nueva bienvenida y a los controles de hábitos. Esta última revisión se verificó solo mediante análisis estático, sin compilar ni ejecutar pruebas por indicación del usuario.

## Estructura

- `core/database/database_service.dart`: conexión y apertura compartida. Mantiene la API del servicio.
- `core/database/database_schema.dart`: creación y migraciones del esquema v4.
- `core/database/repositories/`: operaciones por responsabilidad: cuentas, movimientos, presupuestos, agenda, notas/hábitos, preferencias, informes y respaldos. Comparten la misma conexión y notificador.
- `core/database/transaction_writer.dart`: escritura de movimientos y saldos dentro de la transacción que recibe, también al pagar compromisos.
- `features/bodega/logic/home_controller.dart`: carga del inicio, selección de cuenta, asignaciones y totales diarios/semanales/mensuales obtenidos en una consulta.
- `features/bodega/presentation/widgets/`: saldo, cuentas, presupuesto, notas/hábitos, calendario y movimientos; la pantalla principal conserva navegación y apertura de formularios.
- Los controles y formularios de hábitos y planificación están separados para reutilizarlos desde Inicio y Mi espacio.

Esta separación no cambia la versión de SQLite ni la ruta de almacenamiento. No se añadieron dependencias.

La revisión de código consolidó la lectura de los gastos del día, semana y mes en una consulta, limita el inicio a cinco movimientos y agrupa los registros de hábitos en un único recorrido. Las transacciones de pagos, lotes y restauración conservan la misma conexión y límites de commit/rollback.
