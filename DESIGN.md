# kwall

App personal para operar con dinero, notas y hábitos. La utilidad manda: registrar, revisar y anticipar con controles cercanos al pulgar, sin acciones en las barras de título.

## Apariencia

Bosque es la paleta inicial: acento `#466539`, fondo `#F5F5EE`, superficie `#FFFEF9`, texto `#292E27` y borde `#555E50`. También se puede elegir Ciruela (`#735085`), Rosa (`#A14665`) o Miel (`#806015`). No usar azul. Los colores antiguos de categorías se adaptan para evitarlo.

Modos claro, oscuro y del sistema, guardados en SQLite. El modo oscuro usa fondo `#1D211E`, superficie `#272D28`, texto `#F1F3E9` y acentos claros con contraste. Los estados usan ingresos verdes y alertas rojas.

Paneles de 18 px de radio y borde de 1 px; campos/botones de 14–18 px y hojas de 24 px. Espaciado de 8 px, contenido limitado a 800 px y formularios a 560 px. Medidas en píxeles lógicos de Flutter. Familia Roboto con fallback de plataforma, sin descargas de fuentes. Iconografía Material consistente, etiquetas cortas y tooltips.

## Interacción

Barra inferior: Inicio, Agenda, Mi espacio y Ajustes; botón + central con gasto, ingreso, transferencia, banco, nota, fecha, categorías, hábitos y apariencia. No añadir acciones al encabezado de las pantallas principales.

El atlas proporcionado `cat.png` es transparente, de 256 × 320 px, con celdas de 32 px. Estados: reposo (fila 0/4 frames), caminar (4/8), correr (5/8), dormir (6/4), curiosidad (7/6), celebración (8/7) y descanso (9/8). El recorte mantiene proporciones y píxeles sin interpolación. Mishi, Canela y Sombra usan el mismo atlas con distintos tonos; una imagen propia fija usa desplazamientos y giros breves al reaccionar. Las imágenes importadas son portables en el respaldo. La animación vive en su propio RepaintBoundary y se detiene si la app está en segundo plano, el tab está oculto o el usuario reduce movimiento.

Respuesta al pulsar de 110 ms, transición de la hoja de movimientos de 180/120 ms, anillos animados de 450 ms y respuesta háptica discreta. Registrar movimientos da 5 XP; completar hábitos da 10 XP por hábito/día; finalizar una lista da 5 XP por lista. Las recompensas son idempotentes y no dependen del dinero gastado. Los niveles avanzan cada 100 XP.

## Pantallas

La primera apertura muestra una bienvenida breve con Empezar y Tengo un respaldo. La carga se muestra durante la apertura real de datos, sin espera artificial; un fallo ofrece Reintentar sin reemplazar datos.

Inicio muestra saldo, moneda espejo, saldo libre, gato, nivel y acciones de movimiento. Los selectores Cuentas/Notas/Hábitos reúnen cuentas con mínimos, vistas de notas con casillas y registro directo de hábitos. Las listas e indicadores de hábitos se actualizan desde SQLite. Se muestran como máximo cinco movimientos recientes y se conserva el acceso al historial completo. Los presupuestos permiten asignar importes por período o adaptarse al saldo libre. Cada cuenta tiene un anillo del mínimo protegido, saldo y edición de su reserva. El historial completo se abre desde Movimientos. El estado y las cargas residen en HomeController; cada sección visual está aislada en un componente.

Agenda muestra un calendario dentro de la app. Tocar selecciona una fecha; Rango permite tocar inicio y final, sin abrir otro selector de rango. Un cuadrado indica pagos y una estrella días especiales. El botón Añadir usa la fecha seleccionada. Se conservan rangos y recurrencias.

Mi espacio contiene notas libres y listas de pendientes editables. Hábitos permite marcar un día como hecho, o registrar ánimo y motivo si no se pudo. La racha se calcula desde los registros diarios y se puede revisar por fecha. El selector semanal corresponde al día elegido; no se permiten marcas futuras. Varios días abre un calendario con selección múltiple y estado de los días registrados. Marcar pendientes completa los hábitos aún sin registro del día, con confirmación. Las escrituras por lote son atómicas y las recompensas no se duplican.

Ajustes reúne paleta/modo, moneda principal y espejo, selección y nombre de mascota, exportación, importación y copias de recuperación. No muestra controles de verificación de integridad ni textos internos sobre atlas, checksum o tablas; las validaciones de datos se mantienen dentro del servicio.

## Datos y cálculos

SQLite v4 migra versiones anteriores sin borrar los registros. Antes de migrar y restaurar, conserva una copia JSON local. Respaldos nuevos llevan checksum SHA-256 sobre datos canónicos; versiones anteriores siguen siendo importables. Se rechazan versiones futuras, campos incompatibles, referencias inválidas y saldos que no concuerdan con saldo inicial más movimientos activos. La importación completa se ejecuta en una transacción; una falla revierte todos los cambios.

Anular un movimiento corrige el saldo y conserva el registro original en `transaction_archive`. Las cuentas se archivan; no se borran sus movimientos. El historial incluye consulta de anulaciones, búsqueda, cuentas, tipos, fechas, paginación por fecha/ID y agregados SQL sobre todo el rango. Las transferencias internas no son ingresos ni gastos.

El saldo inicial histórico se deriva en la migración del saldo existente y los movimientos conservados. Los cálculos no se basan en la lista visible del inicio. Los importes se mantienen en una unidad principal común; cambiar el símbolo no convierte montos. La moneda espejo usa una tasa manual.

El presupuesto por saldo libre protege los mínimos de las cuentas y los compromisos vencidos/próximos 30 días; suma los gastos del período para no descontarlos dos veces. Los límites manuales se guardan para su período, con compatibilidad para los presupuestos base antiguos.

## Evidencia

Pruebas de migración v2/v3, respaldo/restauración y rechazo de daños, interrupción simulada durante restauración, idempotencia, historial largo y pantallas compactas/amplias. Las capturas existentes preceden a la nueva bienvenida y al centro personal de Inicio. Esta última ampliación solo pasó revisión estática: no se compila ni ejecutan pruebas por indicación del usuario. Las capturas son renders de widgets con datos sintéticos; no certifican FPS, teclado ni comportamiento de un dispositivo Android real.
