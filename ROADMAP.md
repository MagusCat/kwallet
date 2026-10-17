# Roadmap de Kwall

Hoja de ruta para las próximas fases de desarrollo de **Kwall**, enfocada en la utilidad cotidiana, reducción de fricción y planificación proactiva entre finanzas, hábitos y la mascota virtual.

---

## 1. Planificación Bancaria y Previsión Financiera

### 1.1. Dinero Libre Real (*Safe-to-Spend*)
- **Estado:** 🔲 En backlog / Próxima fase
- **Objetivo:** Evitar la falsa sensación de liquidez descontando anticipadamente los compromisos inmediatos.
- **Detalle de implementación:**
  - Cálculo visible en el Home que toma el saldo disponible en efectivo y resta los compromisos, gastos recurrentes y suscripciones que vencen dentro del horizonte configurable (próximos 7 a 15 días o fin de ciclo).
  - Cálculo adaptado por cada moneda dominante registrada en las cuentas.
  - Indicador visual rápido que avisa si el ritmo de gasto diario actual compromete los pagos fijos futuros.

### 1.2. Calendario Visual de Vencimientos y Flujo de Caja
- **Estado:** ✅ Completado
- **Objetivo:** Anticipar salidas de dinero y asegurar la liquidez en la cuenta y moneda correspondiente.
- **Detalle de implementación:**
  - Vista en la Agenda/Calendario con marcas claras de cobros programados para cada día del mes.
  - Agrupación por moneda dominante y cuenta origen asignada.
  - Alerta preventiva cuando el saldo proyectado de una cuenta sea inferior al total de compromisos que se liquidarán en ella.

### 1.3. Registro Rápido de "Gastos Hormiga" (*1-Tap Fast Logging*)
- **Estado:** ✅ Completado
- **Objetivo:** Eliminar la fricción de registrar pagos pequeños y repetitivos (café, transporte, meriendas, propinas).
- **Detalle de implementación:**
  - Chips de acción rápida configurables por el usuario en el Home o en la hoja de nuevo movimiento.
  - Cada chip almacena concepto, categoría, importe y moneda dominante preestablecidos.
  - Registro inmediato con confirmación háptica discreta y opción de deshacer en 3 segundos.

---

## 2. Hábitos y Productividad Diaria

### 2.1. Bloques Horarios para Hábitos (Mañana / Tarde / Noche)
- **Estado:** ✅ Completado
- **Objetivo:** Reducir la sobrecarga cognitiva filtrando la lista de hábitos según el momento del día.
- **Detalle de implementación:**
  - Campo opcional `time_block` en la definición del hábito (`morning`, `afternoon`, `evening`, `anytime`).
  - Filtrado inteligente en el Home y en la sección de Hábitos: muestra por defecto el bloque activo según la hora local, con pestañas o alternadores rápidos para consultar los demás bloques.
  - Estadísticas de cumplimiento por momento del día.

### 2.2. Cierre del Día (*Daily Recap* en 30 segundos)
- **Estado:** 🔲 En backlog
- **Objetivo:** Consolidar el hábito de cierre nocturno y preparación para el día siguiente.
- **Detalle de implementación:**
  - Flujo breve al anochecer (accesible mediante botón o tarjeta en el Home):
    1. Revisión de hábitos del día (marcar pendientes o indicar motivo de no realización).
    2. Resumen consolidado del gasto del día desglosado por moneda.
    3. Resumen de XP ganado durante la jornada y actualización del estado de ánimo de la mascota.
  - Cierre formal del día con animación de descanso de la mascota.

### 2.3. Notas con Recordatorio / Fecha Límite Integrada a la Agenda
- **Estado:** ✅ Completado
- **Objetivo:** Conectar las notas y listas de pendientes con la planificación temporal.
- **Detalle de implementación:**
  - Posibilidad de asignar una fecha límite u objetivo a ítems específicos dentro de listas y notas.
  - Sincronización con la vista diaria de la Agenda: los pendientes con fecha del día aparecen como ítems de acción inmediata junto a los hábitos y pagos.

---

## 3. Sinergia y Gamificación con la Mascota

### 3.1. Comentarios y Reacciones Contextuales de la Mascota
- **Estado:** ✅ Completado
- **Objetivo:** Reforzar positivamente la constancia y el progreso del usuario con interacciones vivas.
- **Detalle de implementación:**
  - Burbujas de diálogo y reacciones de la mascota basadas en eventos reales del día:
    - *Cumplimiento temprano:* Si se completan todos los hábitos de la mañana antes del mediodía, la mascota muestra animación de celebración.
    - *Control de presupuesto:* Si los gastos se mantienen dentro del límite previsto, la mascota descansa plácidamente.
    - *Días difíciles:* Si se registran ánimos bajos en el diario, ofrece acompañamiento tranquilo.
  - Iconografía visual pura (sin texto ni emojis) físicamente integrada sobre el escenario de la mascota y oculta en reposo.

### 3.2. Especies Compañeras, Mecánica de Crecimiento y Notificaciones del Sistema
- **Estado:** ✅ Completado
- **Objetivo:** Enriquecer el vínculo emocional con diversas especies, evolución por experiencia y alertas nativas respetando las preferencias del usuario.
- **Detalle de implementación:**
  - Selección de especie: Gato, Rata y Mapache (con opción de elección directa o al azar).
  - Mecánica de crecimiento y sprites baby: forma cría cuando XP < 200 con atlases pixel art limpios de 32×32 sin recorte.
  - Notificaciones nativas para Android (canales de hábitos, finanzas y mascota) con opción de desactivar tipos o silenciar por completo.

---

## Criterios Técnicos de Ejecución
- **Persistencia Local:** Todos los datos se almacenan en SQLite local (migración incremental de esquema sin alterar datos existentes).
- **Cero dependencias externas invasivas:** Mantener la pureza de Flutter y plugins esenciales del proyecto.
- **Rendimiento:** Las consultas de resumen diario y calendario deben ejecutarse en queries consolidadas para mantener 60 FPS estables.
