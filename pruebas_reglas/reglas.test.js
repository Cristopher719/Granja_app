import { readFileSync } from 'node:fs';
import { before, after, test } from 'node:test';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, query, where,
} from 'firebase/firestore';

let env;
const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const hoy = new Date();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-granja',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    const usuarios = {
      admin1: { rol: 'administrador', nombre: 'Admin 1' },
      admin2: { rol: 'administrador', nombre: 'Admin 2' },
      prop: { rol: 'propietario', creado_por: 'admin1' },
      galp: { rol: 'galponero', creado_por: 'admin1' },
      galp2: { rol: 'galponero', creado_por: 'admin2' },
      vend: { rol: 'vendedor', creado_por: 'admin1' },
      bod: { rol: 'bodeguero', creado_por: 'admin1' },
    };
    for (const [uid, datos] of Object.entries(usuarios)) await setDoc(doc(d, 'usuarios', uid), datos);
    await setDoc(doc(d, 'galpones/g1'), { nombre_o_numero: 'G1', administrador_id: 'admin1', galponero_id: 'galp' });
    await setDoc(doc(d, 'galpones/g2'), { nombre_o_numero: 'G2', administrador_id: 'admin2', galponero_id: 'galp2' });
    await setDoc(doc(d, 'galpones/gdemo'), { nombre_o_numero: 'Demo', administrador_id: 'admin1', es_demo: true });
    await setDoc(doc(d, 'galpones/g1/lotes_aves/l1'), { raza: 'ISA Brown', cantidad_inicial: 1000 });
    await setDoc(doc(d, 'galpones/g1/lotes_aves/l1/registros_diarios/r1'), { registrado_por: 'galp', mortalidad: 2, fecha: hoy });
    await setDoc(doc(d, 'ventas/v1'), { vendedor_id: 'vend', cantidad_unidades: 30, fecha: hoy });
    await setDoc(doc(d, 'ventas/v2'), { vendedor_id: 'otro_vendedor', cantidad_unidades: 10, fecha: hoy });
    await setDoc(doc(d, 'clientes/c1'), { admin_id: 'admin1', creado_por: 'vend', nombre: 'Cliente 1' });
    await setDoc(doc(d, 'clientes/c2'), { admin_id: 'admin2', creado_por: 'admin2', nombre: 'Cliente 2' });
    await setDoc(doc(d, 'metricas_desempeno/m1'), { usuario_id: 'admin1', operacion: 'registro_venta', ms: 200, fecha: hoy });
  });
});

after(async () => { await env?.cleanup(); });

const R = 'galpones/g1/lotes_aves/l1/registros_diarios';

test('01 Un usuario sin sesión no puede leer perfiles (DENEGADO)', () =>
  assertFails(getDoc(doc(db(null), 'usuarios/galp'))));
test('02 El galponero lee su propio perfil (PERMITIDO)', () =>
  assertSucceeds(getDoc(doc(db('galp'), 'usuarios/galp'))));
test('03 El galponero no lee el perfil de otro usuario (DENEGADO)', () =>
  assertFails(getDoc(doc(db('galp'), 'usuarios/vend'))));
test('04 El vendedor no puede crear usuarios (DENEGADO)', () =>
  assertFails(setDoc(doc(db('vend'), 'usuarios/nuevo1'), { rol: 'vendedor', creado_por: 'admin1' })));
test('05 El administrador crea un usuario (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('admin1'), 'usuarios/nuevo2'), { rol: 'vendedor', creado_por: 'admin1' })));
test('06 El administrador no puede cambiar el rol de un usuario (DENEGADO)', () =>
  assertFails(updateDoc(doc(db('admin1'), 'usuarios/galp'), { rol: 'administrador' })));
test('07 Un usuario registra su propio consentimiento (PERMITIDO)', () =>
  assertSucceeds(updateDoc(doc(db('bod'), 'usuarios/bod'), {
    consentimiento_aceptado: true, fecha_consentimiento: hoy, version_politica: '1.0',
  })));
test('08 Un usuario no puede cambiarse su propio rol (DENEGADO)', () =>
  assertFails(updateDoc(doc(db('vend'), 'usuarios/vend'), { rol: 'administrador' })));
test('09 Ni el administrador puede borrar usuarios (DENEGADO)', () =>
  assertFails(deleteDoc(doc(db('admin1'), 'usuarios/galp'))));

test('10 El administrador crea un galpón propio (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('admin1'), 'galpones/g3'), { nombre_o_numero: 'G3', administrador_id: 'admin1' })));
test('11 El administrador no crea galpones a nombre de otro (DENEGADO)', () =>
  assertFails(setDoc(doc(db('admin1'), 'galpones/g4'), { nombre_o_numero: 'G4', administrador_id: 'admin2' })));
test('12 El administrador no lee galpones de otro administrador (DENEGADO)', () =>
  assertFails(getDoc(doc(db('admin1'), 'galpones/g2'))));
test('13 El galponero lee el galpón que tiene asignado (PERMITIDO)', () =>
  assertSucceeds(getDoc(doc(db('galp'), 'galpones/g1'))));
test('14 El galponero no puede listar todos los galpones (DENEGADO)', () =>
  assertFails(getDocs(collection(db('galp'), 'galpones'))));
test('15 El galponero lista solo sus galpones con filtro (PERMITIDO)', () =>
  assertSucceeds(getDocs(query(collection(db('galp'), 'galpones'), where('galponero_id', '==', 'galp')))));
test('16 El vendedor no puede modificar un galpón (DENEGADO)', () =>
  assertFails(updateDoc(doc(db('vend'), 'galpones/g1'), { nombre_o_numero: 'X' })));
test('17 El administrador no puede borrar un galpón real (DENEGADO)', () =>
  assertFails(deleteDoc(doc(db('admin1'), 'galpones/g1'))));
test('18 El administrador borra su galpón de demostración (PERMITIDO)', () =>
  assertSucceeds(deleteDoc(doc(db('admin1'), 'galpones/gdemo'))));

test('19 El galponero registra el día en su galpón (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('galp'), `${R}/r2`), { registrado_por: 'galp', mortalidad: 1, fecha: hoy })));
test('20 El galponero no registra en un galpón ajeno (DENEGADO)', () =>
  assertFails(setDoc(doc(db('galp'), 'galpones/g2/lotes_aves/l9/registros_diarios/r3'), { registrado_por: 'galp', mortalidad: 1, fecha: hoy })));
test('21 El galponero no registra a nombre de otro usuario (DENEGADO)', () =>
  assertFails(setDoc(doc(db('galp'), `${R}/r4`), { registrado_por: 'otro', mortalidad: 1, fecha: hoy })));
test('22 Nadie puede editar un registro diario guardado (DENEGADO)', () =>
  assertFails(updateDoc(doc(db('galp'), `${R}/r1`), { mortalidad: 0 })));
test('23 El vendedor no lee los registros diarios (DENEGADO)', () =>
  assertFails(getDoc(doc(db('vend'), `${R}/r1`))));
test('24 El bodeguero lee los registros diarios para el stock (PERMITIDO)', () =>
  assertSucceeds(getDoc(doc(db('bod'), `${R}/r1`))));

test('25 El bodeguero registra una clasificación (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('bod'), 'clasificacion_huevos/k1'), { bodeguero_id: 'bod', id_galpon: 'g1', total: 30, fecha: hoy })));
test('26 El vendedor no registra clasificaciones (DENEGADO)', () =>
  assertFails(setDoc(doc(db('vend'), 'clasificacion_huevos/k2'), { bodeguero_id: 'vend', id_galpon: 'g1', total: 30, fecha: hoy })));

test('27 El vendedor registra una venta propia (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('vend'), 'ventas/v3'), { vendedor_id: 'vend', cantidad_unidades: 12, fecha: hoy })));
test('28 El vendedor no registra ventas a nombre de otro (DENEGADO)', () =>
  assertFails(setDoc(doc(db('vend'), 'ventas/v4'), { vendedor_id: 'otro_vendedor', cantidad_unidades: 12, fecha: hoy })));
test('29 El vendedor no ve las ventas de otro vendedor (DENEGADO)', () =>
  assertFails(getDoc(doc(db('vend'), 'ventas/v2'))));
test('30 El propietario no puede registrar ventas (DENEGADO)', () =>
  assertFails(setDoc(doc(db('prop'), 'ventas/v5'), { vendedor_id: 'prop', cantidad_unidades: 12, fecha: hoy })));
test('31 Nadie puede editar una venta guardada (DENEGADO)', () =>
  assertFails(updateDoc(doc(db('admin1'), 'ventas/v1'), { cantidad_unidades: 1 })));

test('32 El bodeguero registra una entrada de alimento (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('bod'), 'inventario_alimento/a1'), { id_galpon: 'g1', tipo: 'entrada', cantidad_kg: 500, fecha: hoy })));
test('33 El galponero no registra entradas de alimento (DENEGADO)', () =>
  assertFails(setDoc(doc(db('galp'), 'inventario_alimento/a2'), { id_galpon: 'g1', tipo: 'entrada', cantidad_kg: 500, fecha: hoy })));

test('34 El vendedor crea un cliente de su operación (PERMITIDO)', () =>
  assertSucceeds(setDoc(doc(db('vend'), 'clientes/c3'), { admin_id: 'admin1', creado_por: 'vend', nombre: 'Cliente 3' })));
test('35 El vendedor no ve clientes de otra operación (DENEGADO)', () =>
  assertFails(getDoc(doc(db('vend'), 'clientes/c2'))));

test('36 El galponero no puede leer las métricas (DENEGADO)', () =>
  assertFails(getDoc(doc(db('galp'), 'metricas_desempeno/m1'))));
test('37 Nadie puede borrar una métrica (DENEGADO)', () =>
  assertFails(deleteDoc(doc(db('admin1'), 'metricas_desempeno/m1'))));
