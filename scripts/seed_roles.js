const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

const { getFirestore } = require('firebase-admin/firestore');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = getFirestore(admin.app(), 'crm-solucionesti');

const roles = [
  {
    id: 'admin',
    label: 'Administrador',
    permissions: {
      'operatividad': 'total',
      'crm': 'total',
      'inventario': 'total',
      'ventas': 'total',
      'marketing': 'total',
      'soporte': 'total',
      'proyectos': 'total'
    }
  },
  {
    id: 'soporte_tecnico',
    label: 'Soporte Técnico',
    permissions: {
      'operatividad': 'edit',
      'crm': 'none',
      'inventario': 'none',
      'marketing': 'none',
      'soporte': 'edit',
      'proyectos': 'none'
    }
  },
  {
    id: 'soporte_sistemas',
    label: 'Soporte Sistemas',
    permissions: {
      'operatividad': 'total',
      'crm': 'edit',
      'inventario': 'total',
      'marketing': 'none',
      'soporte': 'total',
      'proyectos': 'total'
    }
  }
];

async function seed() {
  const rolesCol = db.collection('roles');
  for (const role of roles) {
    await rolesCol.doc(role.id).set(role);
    console.log(`Role ${role.id} seeded.`);
  }
  process.exit(0);
}

seed().catch(err => {
  console.error(err);
  process.exit(1);
});
