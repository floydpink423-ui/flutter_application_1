final auth = AuthService();

Future<void> login() async {
  try {
    final user = await auth.login(
      userController.text.trim(),
      passController.text.trim(),
    );

    final rol = await auth.getRol(user!.uid);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ListaDuctos(rol: rol),
      ),
    );
  } catch (e) {
    setState(() => error = "Error de login");
  }
}
