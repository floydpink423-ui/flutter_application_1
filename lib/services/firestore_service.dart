class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUsuario(String uid) {
    return _db.collection("usuarios").doc(uid).get();
  }

  Stream<QuerySnapshot> ductosStream() {
    return _db.collection("ductos").snapshots();
  }

  Future<void> actualizarDucto(String id, Map<String, dynamic> data) {
    return _db.collection("ductos").doc(id).update(data);
  }
}
