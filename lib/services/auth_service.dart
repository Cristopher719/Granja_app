import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firestore_service.dart';
import 'notificacion_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get cambiosDeUsuario => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  static const List<String> rolesValidos = [
    'administrador',
    'propietario',
    'galponero',
    'vendedor',
    'bodeguero',
  ];

  static const Map<String, String> etiquetasRol = {
    'administrador': 'Administrador',
    'propietario': 'Propietario',
    'galponero': 'Galponero',
    'vendedor': 'Vendedor',
    'bodeguero': 'Bodeguero',
  };

  Future<String> crearUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String creadoPorAdminId,
  }) async {
    assert(
      rolesValidos.contains(rol),
      'Rol inválido: $rol. Debe ser uno de: $rolesValidos',
    );

    final appSecundaria = await Firebase.initializeApp(
      name: 'appSecundaria_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final authSecundaria = FirebaseAuth.instanceFor(app: appSecundaria);

    try {
      final credenciales = await authSecundaria.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );

      final uid = credenciales.user!.uid;

      await _firestoreService.crearUsuario(
        uid: uid,
        nombre: nombre,
        correo: correo,
        rol: rol,
        creadoPor: creadoPorAdminId,
      );

      return uid;
    } finally {
      await authSecundaria.signOut();
      await appSecundaria.delete();
    }
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final credenciales = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );

    final uid = credenciales.user!.uid;
    final datos = await _firestoreService.obtenerUsuario(uid);
    if (datos?['rol'] == 'administrador') {
      await NotificacionService().suscribirATopic(
        NotificacionService.topicAdmin(uid),
      );
    }
  }

  Future<void> cerrarSesion() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final datos = await _firestoreService.obtenerUsuario(uid);
      if (datos?['rol'] == 'administrador') {
        await NotificacionService().desuscribirDeTopic(
          NotificacionService.topicAdmin(uid),
        );
      }
    }
    await _auth.signOut();
  }

  Future<String?> obtenerRolUsuario(String uid) async {
    final datos = await _firestoreService.obtenerUsuario(uid);
    return datos?['rol'] as String?;
  }

  Future<void> cambiarContrasena(String nuevaContrasena) async {
    await _auth.currentUser?.updatePassword(nuevaContrasena);
  }
}
