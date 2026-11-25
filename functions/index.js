const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const UMBRAL_MORTALIDAD = 5;
const UMBRAL_STOCK_KG = 100;

const RUTA_REGISTRO =
  "galpones/{galponId}/lotes_aves/{loteId}/registros_diarios/{registroId}";

async function datosGalpon(galponId) {
  const doc = await db.collection("galpones").doc(galponId).get();
  if (!doc.exists) return null;
  const d = doc.data();
  return {
    adminId: d?.administrador_id,
    nombre: d?.nombre_o_numero ?? "Galpón",
  };
}

async function stockAlimento(galponId) {
  const ahora = Date.now();
  const ms = (t) => (t?.toMillis ? t.toMillis() : ahora);

  const movSnap = await db
    .collection("inventario_alimento")
    .where("id_galpon", "==", galponId)
    .get();
  const movs = movSnap.docs.map((d) => d.data());

  const conteos = movs.filter((m) => m.tipo === "conteo");
  const ultimo = conteos.sort((a, b) => ms(b.fecha) - ms(a.fecha))[0];
  const corte = ultimo ? ms(ultimo.fecha) : null;
  const base = ultimo?.cantidad_kg ?? 0;

  const entradas = movs
    .filter((m) => m.tipo === "entrada" && (corte === null || ms(m.fecha) > corte))
    .reduce((s, m) => s + (m.cantidad_kg ?? 0), 0);

  const lotesSnap = await db.collection("galpones").doc(galponId).collection("lotes_aves").get();
  let consumo = 0;
  for (const lote of lotesSnap.docs) {
    const regs = (await lote.ref.collection("registros_diarios").get()).docs.map((d) => d.data());
    const dia = (r) => new Date(ms(r.fecha)).toISOString().slice(0, 10);
    const correcciones = {};
    for (const r of regs.filter((r) => r.es_correccion === true)) {
      const k = dia(r);
      if (!correcciones[k] || ms(r.fecha) > ms(correcciones[k].fecha)) correcciones[k] = r;
    }
    const efectivos = [
      ...regs.filter((r) => r.es_correccion !== true && !correcciones[dia(r)]),
      ...Object.values(correcciones),
    ];
    consumo += efectivos
      .filter((r) => corte === null || ms(r.fecha) > corte)
      .reduce((s, r) => s + (r.alimento_kg ?? 0), 0);
  }
  return Math.max(0, base + entradas - consumo);
}

async function enviarAlerta({ adminId, titulo, cuerpo, canal, datos, eventoEn }) {
  const esAlerta = canal === "alertas_granja";
  await messaging.send({
    topic: `alertas_admin_${adminId}`,
    notification: { title: titulo, body: cuerpo },
    android: {
      notification: {
        channelId: canal,
        priority: esAlerta ? "high" : "default",
        ...(esAlerta ? { sound: "default" } : {}),
      },
    },
    apns: {
      payload: {
        aps: { alert: { title: titulo, body: cuerpo }, sound: "default" },
      },
    },
    data: {
      ...datos,
      evento_en: String(eventoEn),
      enviado_en: String(Date.now()),
    },
  });
}

function momentoEvento(datos) {
  return datos?.fecha?.toMillis?.() ?? Date.now();
}

async function alertarSiStockBajo(galponId, eventoEn) {
  const stock = await stockAlimento(galponId);
  if (stock >= UMBRAL_STOCK_KG) return;

  const galpon = await datosGalpon(galponId);
  if (!galpon?.adminId) return;

  await enviarAlerta({
    adminId: galpon.adminId,
    titulo: "📦 Stock bajo de alimento",
    cuerpo: `${galpon.nombre}: solo ${stock.toFixed(0)} kg disponibles.`,
    canal: "alertas_granja",
    datos: {
      tipo: "stock_bajo",
      galpon_id: galponId,
      nombre_galpon: galpon.nombre,
      stock: stock.toString(),
    },
    eventoEn,
  });
  console.log(`Alerta de stock bajo (${stock} kg) para ${galpon.nombre}`);
}

exports.alertaMortalidadAlta = onDocumentCreated(RUTA_REGISTRO, async (event) => {
  const datos = event.data?.data();
  if (!datos) return;

  const mortalidad = datos.mortalidad ?? 0;
  if (mortalidad <= UMBRAL_MORTALIDAD) return;

  const galponId = event.params.galponId;
  const galpon = await datosGalpon(galponId);
  if (!galpon?.adminId) return;

  await enviarAlerta({
    adminId: galpon.adminId,
    titulo: "⚠️ Alerta de mortalidad",
    cuerpo: `${galpon.nombre}: ${mortalidad} aves muertas hoy.`,
    canal: "alertas_granja",
    datos: {
      tipo: "mortalidad",
      galpon_id: galponId,
      nombre_galpon: galpon.nombre,
      mortalidad: mortalidad.toString(),
    },
    eventoEn: momentoEvento(datos),
  });
  console.log(`Alerta de mortalidad (${mortalidad}) para ${galpon.nombre}`);
});

exports.alertaStockBajo = onDocumentCreated(
  "inventario_alimento/{movimientoId}",
  async (event) => {
    const datos = event.data?.data();
    if (!datos || !["entrada", "conteo"].includes(datos.tipo) || !datos.id_galpon) return;
    await alertarSiStockBajo(datos.id_galpon, momentoEvento(datos));
  }
);

exports.alertaStockBajoPorConsumo = onDocumentCreated(
  RUTA_REGISTRO,
  async (event) => {
    const datos = event.data?.data();
    if (!datos || !(datos.alimento_kg > 0)) return;
    await alertarSiStockBajo(event.params.galponId, momentoEvento(datos));
  }
);

exports.notificarRegistroDiario = onDocumentCreated(
  RUTA_REGISTRO,
  async (event) => {
    const datos = event.data?.data();
    if (!datos) return;

    const galponId = event.params.galponId;
    const galpon = await datosGalpon(galponId);
    if (!galpon?.adminId) return;

    await enviarAlerta({
      adminId: galpon.adminId,
      titulo: "🥚 Nuevo registro diario",
      cuerpo: `${galpon.nombre}: ${datos.huevos_buenos ?? 0} huevos registrados hoy.`,
      canal: "info_granja",
      datos: {
        tipo: "registro_diario",
        galpon_id: galponId,
        nombre_galpon: galpon.nombre,
      },
      eventoEn: momentoEvento(datos),
    });
  }
);
