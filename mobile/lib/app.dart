import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/offline/offline_scan_queue.dart';

const ivory = Color(0xFFF8F4ED);
const champagne = Color(0xFFC49A67);
const ink = Color(0xFF352D29);
const rose = Color(0xFFE9D5D0);
final appConfig = AppConfig.fromEnvironment();

Color _hexColor(String? value, Color fallback) {
  final normalized = value?.replaceFirst('#', '');
  if (normalized == null || normalized.length != 6) return fallback;
  final color = int.tryParse('FF$normalized', radix: 16);
  return color == null ? fallback : Color(color);
}

String? _eventLogoUrl(String? logo) {
  if (logo == null || logo.isEmpty) return null;
  if (logo.startsWith('http://') || logo.startsWith('https://')) return logo;
  final apiUri = Uri.parse(appConfig.apiBaseUrl);
  return '${apiUri.origin}/storage/${logo.replaceFirst(RegExp(r'^/+'), '')}';
}

String _formatEventDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:00';
}

DateTime? _parseEventDate(String value) {
  return DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
}

String _invitationDate(String value) {
  final parsed = _parseEventDate(value);
  if (parsed == null) return value;
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}\nà $hour h $minute';
}

String _joinInvitationDetails(Iterable<String?> values) {
  return values
      .where((value) => value != null && value.trim().isNotEmpty)
      .map((value) => value!.trim())
      .join('\n');
}

class _ColorChoice {
  const _ColorChoice(this.name, this.value);

  final String name;
  final String value;

  Color get color => _hexColor(value, Colors.white);
}

const _colorChoices = [
  _ColorChoice('Champagne', '#C49A67'),
  _ColorChoice('Terracotta', '#C66B52'),
  _ColorChoice('Rose poudré', '#D9A6A1'),
  _ColorChoice('Sauge', '#879B82'),
  _ColorChoice('Bleu brume', '#8FA9B8'),
  _ColorChoice('Ivoire', '#F7F1E8'),
  _ColorChoice('Prune', '#765568'),
  _ColorChoice('Noir élégant', '#352D29'),
];

class MariageApp extends StatelessWidget {
  const MariageApp({this.initialToken, this.initialRole = 'staff', super.key});

  final String? initialToken;
  final String initialRole;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: champagne,
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bienvenue au mariage',
      theme: ThemeData(
        colorScheme: scheme.copyWith(
          surface: ivory,
          primary: ink,
          secondary: champagne,
        ),
        scaffoldBackgroundColor: ivory,
        fontFamily: 'Georgia',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: .7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: champagne),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: initialToken == null
          ? const WelcomeScreen()
          : EventSelectionScreen(token: initialToken!, role: initialRole),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF8), ivory, Color(0xFFF1E5D8)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -8,
              left: -30,
              child: Opacity(
                opacity: .9,
                child: Image.asset(
                  'lib/assets/images/images5-removebg-preview.png',
                  width: 205,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -12,
              child: Transform.rotate(
                angle: 3.1416,
                child: Opacity(
                  opacity: .82,
                  child: Image.asset(
                    'lib/assets/images/images5-removebg-preview.png',
                    width: 205,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 76,
              right: -34,
              child: Opacity(
                opacity: .2,
                child: Image.asset(
                  'lib/assets/images/images2-removebg-preview.png',
                  width: 180,
                ),
              ),
            ),
            Positioned(
              bottom: 112,
              left: -34,
              child: Opacity(
                opacity: .16,
                child: Image.asset(
                  'lib/assets/images/Cadre-removebg-preview.png',
                  width: 150,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: Column(
                  children: [
                    const Text(
                      'UNE INVITATION POUR TOUJOURS',
                      style: TextStyle(
                        color: champagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/image.png',
                          width: 205,
                          height: 205,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 16,
                          child: Image.asset(
                            'lib/assets/images/images-removebg-preview (1).png',
                            width: 96,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bienvenue',
                      style: TextStyle(
                        color: champagne,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'au mariage de',
                      style: TextStyle(color: ink, fontSize: 19),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Votre mariage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(width: 74, height: 1, color: champagne),
                    const SizedBox(height: 16),
                    const Text(
                      'Gérez vos invitations avec élégance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF806E60),
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(fontFamily: 'Georgia', fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Gestion des invitations',
                      style: TextStyle(color: Color(0xFF806E60), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool passwordVisible = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final client = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      final response = await client.post(
        '${appConfig.apiBaseUrl}/auth/login',
        data: {
          'email': email.text.trim().toLowerCase(),
          'password': password.text,
        },
      );
      if (!mounted) return;
      final token = response.data['token'] as String;
      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_token', token);
      await preferences.setString(
        'auth_role',
        user['role']?.toString() ?? 'staff',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EventSelectionScreen(
            token: token,
            role: user['role']?.toString() ?? 'staff',
          ),
        ),
      );
    } on DioException catch (exception) {
      final responseData = exception.response?.data;
      final serverMessage = responseData is Map
          ? responseData['message']?.toString()
          : null;
      final message = switch (exception.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          'Serveur inaccessible. Vérifiez que le téléphone et le PC sont sur le même Wi-Fi.',
        _ when exception.response?.statusCode == 422 =>
          serverMessage ?? 'Email ou mot de passe incorrect.',
        _ =>
          serverMessage ??
              'Erreur serveur (${exception.response?.statusCode ?? 'inconnue'}).',
      };
      if (mounted) setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 26),
          const Text(
            'Ravi de vous retrouver',
            style: TextStyle(color: ink, fontSize: 30),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connectez-vous pour gérer les entrées.',
            style: TextStyle(color: Color(0xFF806E60)),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: !passwordVisible,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: passwordVisible
                    ? 'Masquer le mot de passe'
                    : 'Afficher le mot de passe',
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => passwordVisible = !passwordVisible),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xFF9D443C)),
              ),
            ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: loading ? null : login,
            child: loading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Se connecter', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

class EventSelectionScreen extends StatefulWidget {
  const EventSelectionScreen({
    required this.token,
    required this.role,
    super.key,
  });
  final String token;
  final String role;

  @override
  State<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _ColorPickerField extends StatelessWidget {
  const _ColorPickerField({
    required this.label,
    required this.controller,
    required this.onSelected,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<_ColorChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = _colorChoices.firstWhere(
      (choice) => choice.value.toLowerCase() == controller.text.toLowerCase(),
      orElse: () => _ColorChoice('Personnalisée', controller.text),
    );
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.palette_outlined, color: selected.color),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._colorChoices.map((choice) {
            final isSelected =
                choice.value.toLowerCase() == controller.text.toLowerCase();
            return Tooltip(
              message: choice.name,
              child: InkWell(
                onTap: () => onSelected(choice),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: choice.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? ink : Colors.black12,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 19,
                          color: choice.color.computeLuminance() > .55
                              ? ink
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              selected.name,
              style: const TextStyle(color: Color(0xFF806E60), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({required this.token, this.event, super.key});
  final String token;
  final Map<String, dynamic>? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  late final TextEditingController name;
  late final TextEditingController bride;
  late final TextEditingController groom;
  late final TextEditingController date;
  late final TextEditingController venue;
  late final TextEditingController address;
  late final TextEditingController primaryColor;
  late final TextEditingController secondaryColor;
  XFile? logoFile;
  String status = 'active';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    name = TextEditingController(text: event?['name']?.toString());
    bride = TextEditingController(text: event?['bride_name']?.toString());
    groom = TextEditingController(text: event?['groom_name']?.toString());
    final existingDate = _parseEventDate(
      event?['event_date']?.toString() ?? '',
    );
    date = TextEditingController(
      text: existingDate == null ? '' : _formatEventDate(existingDate),
    );
    venue = TextEditingController(text: event?['venue']?.toString());
    address = TextEditingController(text: event?['address']?.toString());
    primaryColor = TextEditingController(
      text: event?['primary_color']?.toString() ?? '#B58B5A',
    );
    secondaryColor = TextEditingController(
      text: event?['secondary_color']?.toString() ?? '#F7F1E8',
    );
    status = event?['status']?.toString() ?? 'active';
  }

  Future<void> pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null && mounted) setState(() => logoFile = picked);
  }

  Future<void> pickDate() async {
    final current = _parseEventDate(date.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Date du mariage',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (selectedDate == null || !mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Heure du mariage',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (selectedTime == null || !mounted) return;
    date.text = _formatEventDate(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
    setState(() {});
  }

  void selectColor(TextEditingController controller, _ColorChoice choice) {
    controller.text = choice.value;
    setState(() {});
  }

  Future<void> save() async {
    if (_parseEventDate(date.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez une date et une heure valides.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    final data = {
      'name': name.text,
      'bride_name': bride.text,
      'groom_name': groom.text,
      'event_date': date.text,
      'venue': venue.text,
      'address': address.text.isEmpty ? null : address.text,
      'primary_color': primaryColor.text.trim(),
      'secondary_color': secondaryColor.text.trim(),
      'status': status,
    };
    try {
      final options = Options(
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      Response<dynamic> response;
      if (widget.event == null) {
        response = await Dio().post(
          '${appConfig.apiBaseUrl}/events',
          data: data,
          options: options,
        );
      } else {
        response = await Dio().put(
          '${appConfig.apiBaseUrl}/events/${widget.event!['id']}',
          data: data,
          options: options,
        );
      }
      final savedEvent = Map<String, dynamic>.from(response.data as Map);
      if (logoFile != null) {
        await Dio().post(
          '${appConfig.apiBaseUrl}/events/${savedEvent['id']}/branding',
          data: FormData.fromMap({
            'logo': await MultipartFile.fromFile(
              logoFile!.path,
              filename: logoFile!.name,
            ),
            'primary_color': primaryColor.text.trim(),
            'secondary_color': secondaryColor.text.trim(),
          }),
          options: options.copyWith(contentType: 'multipart/form-data'),
        );
      }
      if (mounted) Navigator.pop(context);
    } on DioException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exception.response?.data['message']?.toString() ??
                  'Enregistrement impossible.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.event == null ? 'Nouvel événement' : 'Modifier l’événement',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom du mariage'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: groom,
          decoration: const InputDecoration(labelText: 'Nom du marié'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bride,
          decoration: const InputDecoration(labelText: 'Nom de la mariée'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: date,
          readOnly: true,
          onTap: pickDate,
          decoration: const InputDecoration(
            labelText: 'Date et heure du mariage',
            hintText: 'Touchez pour choisir',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: venue,
          decoration: const InputDecoration(labelText: 'Lieu'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: address,
          decoration: const InputDecoration(labelText: 'Adresse'),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Couleur principale',
          controller: primaryColor,
          onSelected: (choice) => selectColor(primaryColor, choice),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Couleur secondaire',
          controller: secondaryColor,
          onSelected: (choice) => selectColor(secondaryColor, choice),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: saving ? null : pickLogo,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            logoFile == null
                ? (widget.event?['logo'] == null
                      ? 'Choisir le logo du billet'
                      : 'Remplacer le logo du billet')
                : 'Image sélectionnée : ${logoFile!.name}',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Statut'),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Actif')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
          ],
          onChanged: (value) => setState(() => status = value ?? 'active'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    ),
  );
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  List<dynamic> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final response = await Dio().get(
        '${appConfig.apiBaseUrl}/events',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      if (mounted) {
        setState(
          () => events = List<dynamic>.from(
            (response.data as Map)['data'] as List,
          ),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger les événements.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void selectEvent(Map<String, dynamic> event) {
    final eventId = event['id'] as int;
    final screen = widget.role == 'admin'
        ? AdminDashboard(token: widget.token, eventId: eventId, event: event)
        : ScannerScreen(token: widget.token, eventId: eventId);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Choisir un événement'),
      actions: [
        if (widget.role == 'admin')
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventFormScreen(token: widget.token),
                ),
              );
              loadEvents();
            },
            icon: const Icon(Icons.add),
            tooltip: 'Créer un événement',
          ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator(color: champagne))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = Map<String, dynamic>.from(events[index] as Map);
              return Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: .75),
                child: ListTile(
                  title: Text(
                    event['name'].toString(),
                    style: const TextStyle(color: ink, fontSize: 18),
                  ),
                  subtitle: Text(
                    '${event['venue']}  •  ${event['status']}',
                    style: const TextStyle(color: Color(0xFF806E60)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: champagne),
                  onTap: () => selectEvent(event),
                ),
              );
            },
          ),
  );
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.token, required this.eventId, super.key});
  final String token;
  final int eventId;
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final controller = MobileScannerController();
  final offlineQueue = OfflineScanQueue();
  bool busy = false;
  Map<String, dynamic>? result;
  bool online = true;
  late final StreamSubscription<List<ConnectivityResult>>
  connectivitySubscription;

  @override
  void initState() {
    super.initState();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      states,
    ) {
      if (mounted) {
        setState(() => online = !states.contains(ConnectivityResult.none));
      }
      if (!states.contains(ConnectivityResult.none)) {
        syncPendingScans();
      }
    });
    syncPendingScans();
  }

  Future<void> syncPendingScans() async {
    final pending = await offlineQueue.all();
    final remaining = <PendingScan>[];
    for (final scan in pending) {
      try {
        await Dio().post(
          '${appConfig.apiBaseUrl}/events/${scan.eventId}/invitations/verify',
          data: {'qr_token': scan.qrToken},
          options: Options(
            headers: {'Authorization': 'Bearer ${widget.token}'},
          ),
        );
      } on DioException catch (exception) {
        if (exception.response == null ||
            exception.response!.statusCode! >= 500) {
          remaining.add(scan);
        }
      }
    }
    await offlineQueue.replace(remaining);
  }

  Future<void> verify(String qrToken) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final response = await Dio().post(
        '${appConfig.apiBaseUrl}/events/${widget.eventId}/invitations/verify',
        data: {'qr_token': qrToken},
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      setState(() => result = Map<String, dynamic>.from(response.data));
    } on DioException catch (exception) {
      if (exception.response == null) {
        await offlineQueue.enqueue(
          PendingScan(
            eventId: widget.eventId,
            qrToken: qrToken,
            createdAt: DateTime.now(),
          ),
        );
        setState(
          () => result = {
            'status': 'pending',
            'message': 'Scan enregistré, synchronisation en attente.',
          },
        );
      } else {
        setState(
          () => result = Map<String, dynamic>.from(exception.response!.data),
        );
      }
    } finally {
      await controller.stop();
      if (mounted) setState(() => busy = false);
    }
  }

  void next() {
    setState(() => result = null);
  }

  @override
  Widget build(BuildContext context) {
    final success = result?['status'] == 'valid';
    return Scaffold(
      backgroundColor: const Color(0xFF191716),
      body: SafeArea(
        child: result == null
            ? Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final value = capture.barcodes.firstOrNull?.rawValue;
                      if (value != null) verify(value);
                    },
                  ),
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: champagne, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scanner une invitation',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        IconButton(
                          onPressed: () => controller.toggleTorch(),
                          color: Colors.white,
                          icon: const Icon(Icons.flash_on),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 34,
                    left: 30,
                    right: 30,
                    child: Text(
                      'Placez le QR Code au centre du cadre',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: 24,
                    child: Text(
                      online ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: online
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              )
            : _ScanResult(result: result!, success: success, onNext: next),
      ),
    );
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    controller.dispose();
    super.dispose();
  }
}

class _ScanResult extends StatelessWidget {
  const _ScanResult({
    required this.result,
    required this.success,
    required this.onNext,
  });
  final Map<String, dynamic> result;
  final bool success;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final guest = result['guest'] as Map<String, dynamic>?;
    final title = success
        ? 'INVITATION VALIDÉE'
        : (result['message'] ?? 'Invitation invalide');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? champagne : rose,
              size: 90,
            ),
            const SizedBox(height: 24),
            Text(
              title.toString().toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            if (success) ...[
              const SizedBox(height: 24),
              const Text(
                'Bienvenue au mariage',
                style: TextStyle(color: champagne, fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                '${guest?['first_name']} ${guest?['last_name']}',
                style: const TextStyle(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 12),
              Text(
                '${guest?['number_of_guests']} personne(s)  •  Table ${guest?['table_number'] ?? '-'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 42),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Scanner l’invité suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    required this.token,
    required this.eventId,
    required this.event,
    super.key,
  });
  final String token;
  final int eventId;
  final Map<String, dynamic> event;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final dio = Dio();
  Map<String, dynamic>? stats;
  List<dynamic> guests = [];
  bool loading = true;

  Options get options =>
      Options(headers: {'Authorization': 'Bearer ${widget.token}'});

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final responses = await Future.wait([
        dio.get(
          '${appConfig.apiBaseUrl}/events/${widget.eventId}/statistics',
          options: options,
        ),
        dio.get(
          '${appConfig.apiBaseUrl}/events/${widget.eventId}/guests?per_page=30',
          options: options,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(responses[0].data as Map);
        guests = List<dynamic>.from((responses[1].data as Map)['data'] as List);
      });
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les invités.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrived = stats?['arrived'] ?? 0;
    final total = stats?['guests'] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vue d’ensemble'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventFormScreen(token: widget.token, event: widget.event),
                ),
              );
              load();
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier l’événement',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanHistoryScreen(
                  token: widget.token,
                  eventId: widget.eventId,
                ),
              ),
            ),
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ScannerScreen(token: widget.token, eventId: widget.eventId),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGuestScreen(
                token: widget.token,
                eventId: widget.eventId,
                event: widget.event,
              ),
            ),
          );
          load();
        },
        backgroundColor: ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Invité'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.event['name'].toString(),
              style: TextStyle(color: ink, fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.event['venue']}  •  ${widget.event['event_date']}',
              style: TextStyle(color: Color(0xFF806E60)),
            ),
            const SizedBox(height: 24),
            if (loading) const LinearProgressIndicator(color: champagne),
            Row(
              children: [
                _StatTile(
                  label: 'Invités',
                  value: '$total',
                  icon: Icons.groups_outlined,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: 'Entrées',
                  value: '$arrived',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatTile(
                  label: 'Restants',
                  value: '${stats?['not_arrived'] ?? 0}',
                  icon: Icons.hourglass_empty,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: 'QR refusés',
                  value: '${stats?['invalid_scans'] ?? 0}',
                  icon: Icons.report_gmailerrorred_outlined,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invités',
                  style: TextStyle(color: ink, fontSize: 21),
                ),
                Text(
                  '${guests.length} affichés',
                  style: const TextStyle(color: Color(0xFF806E60)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...guests.map(
              (guest) => _GuestTile(
                guest: Map<String, dynamic>.from(guest as Map),
                event: widget.event,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Colors.white.withValues(alpha: .75),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: champagne),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(color: ink, fontSize: 25)),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF806E60), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({required this.guest, required this.event});
  final Map<String, dynamic> guest;
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final name = '${guest['first_name']} ${guest['last_name']}';
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .72),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rose,
          child: Text((guest['first_name'] as String? ?? '?').substring(0, 1)),
        ),
        title: Text(name, style: const TextStyle(color: ink)),
        subtitle: Text(
          '${guest['category']}  •  ${guest['number_of_guests']} personne(s)',
          style: const TextStyle(color: Color(0xFF806E60)),
        ),
        trailing: Icon(
          guest['used_at'] == null
              ? Icons.radio_button_unchecked
              : Icons.check_circle,
          color: guest['used_at'] == null ? champagne : Colors.green,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QrCardScreen(guest: guest, event: event),
          ),
        ),
      ),
    );
  }
}

class CreateGuestScreen extends StatefulWidget {
  const CreateGuestScreen({
    required this.token,
    required this.eventId,
    required this.event,
    super.key,
  });
  final String token;
  final int eventId;
  final Map<String, dynamic> event;
  @override
  State<CreateGuestScreen> createState() => _CreateGuestScreenState();
}

class _CreateGuestScreenState extends State<CreateGuestScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final count = TextEditingController(text: '1');
  bool loading = false;

  Future<void> create() async {
    setState(() => loading = true);
    try {
      final response = await Dio().post(
        '${appConfig.apiBaseUrl}/events/${widget.eventId}/guests',
        data: {
          'first_name': firstName.text,
          'last_name': lastName.text,
          'email': email.text.isEmpty ? null : email.text,
          'category': 'Autre',
          'number_of_guests': int.tryParse(count.text) ?? 1,
        },
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QrCardScreen(
            guest: Map<String, dynamic>.from(response.data as Map),
            event: widget.event,
          ),
        ),
      );
    } on DioException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exception.response?.data['message']?.toString() ??
                  'Création impossible.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle invitation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: firstName,
            decoration: const InputDecoration(labelText: 'Prénom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lastName,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre de personnes'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : create,
            child: Text(loading ? 'Création...' : 'Créer l’invitation'),
          ),
        ],
      ),
    );
  }
}

class QrCardScreen extends StatefulWidget {
  const QrCardScreen({required this.guest, required this.event, super.key});
  final Map<String, dynamic> guest;
  final Map<String, dynamic> event;

  @override
  State<QrCardScreen> createState() => _QrCardScreenState();
}

class _QrCardScreenState extends State<QrCardScreen> {
  final screenshotController = ScreenshotController();

  Future<void> shareCard() async {
    final bytes = await screenshotController.capture(pixelRatio: 2.5);
    if (bytes == null || !mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Invitation de mariage - ${widget.guest['first_name']} ${widget.guest['last_name']}',
        files: [
          XFile.fromData(bytes, mimeType: 'image/png', name: 'invitation.png'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bride = widget.event['bride_name']?.toString() ?? '';
    final groom = widget.event['groom_name']?.toString() ?? '';
    final eventName = widget.event['name']?.toString() ?? 'Votre mariage';
    final date = widget.event['event_date']?.toString() ?? '';
    final venue = widget.event['venue']?.toString() ?? '';
    final address = widget.event['address']?.toString() ?? '';
    final message = widget.event['invitation_message']?.toString() ?? '';
    final category = widget.guest['category']?.toString() ?? '';
    final guestCount = widget.guest['number_of_guests']?.toString() ?? '';
    final table = widget.guest['table_number']?.toString() ?? '';
    final primary = _hexColor(
      widget.event['primary_color']?.toString(),
      champagne,
    );
    final secondary = _hexColor(
      widget.event['secondary_color']?.toString(),
      const Color(0xFFFFFCF7),
    );
    final logoUrl = _eventLogoUrl(widget.event['logo']?.toString());
    final guestName =
        '${widget.guest['first_name'] ?? ''} ${widget.guest['last_name'] ?? ''}'
            .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte d’invitation'),
        actions: [
          IconButton(
            onPressed: shareCard,
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Screenshot(
            controller: screenshotController,
            child: Container(
              width: 520,
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
              decoration: BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    width: 150,
                    height: 150,
                    child: Opacity(
                      opacity: .34,
                      child: Image.asset(
                        'lib/assets/images/images2-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -32,
                    left: -22,
                    width: 145,
                    height: 145,
                    child: Transform.rotate(
                      angle: 1.5708,
                      child: Image.asset(
                        'lib/assets/images/images5-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -14,
                    left: 165,
                    width: 145,
                    height: 145,
                    child: Transform.rotate(
                      angle: 3.1416,
                      child: Image.asset(
                        'lib/assets/images/images5-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -28,
                    right: -24,
                    width: 145,
                    height: 145,
                    child: Transform.rotate(
                      angle: 4.7124,
                      child: Image.asset(
                        'lib/assets/images/images5-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -12,
                    left: -38,
                    width: 145,
                    height: 145,
                    child: Transform.rotate(
                      angle: 0,
                      child: Image.asset(
                        'lib/assets/images/images5-removebg-preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    right: 16,
                    width: 82,
                    child: Image.asset(
                      'lib/assets/images/images-removebg-preview (1).png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Column(
                    children: [
                      if (logoUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            logoUrl,
                            width: 120,
                            height: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _initials(bride, groom),
                            style: TextStyle(
                              color: primary,
                              fontFamily: 'Georgia',
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'I N V I T A T I O N',
                        style: TextStyle(
                          color: Color(0xFF9A6925),
                          fontSize: 15,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _goldDivider(primary),
                      const SizedBox(height: 10),
                      Text(
                        guestName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ink,
                          fontFamily: 'Georgia',
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(Icons.favorite, color: primary, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        'Mariage de $eventName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF806E60),
                          fontSize: 17,
                        ),
                      ),
                      if (bride.isNotEmpty || groom.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${groom.isEmpty ? '' : groom}${groom.isNotEmpty && bride.isNotEmpty ? '  &  ' : ''}$bride',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB57D2D),
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF806E60),
                            fontSize: 14,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primary),
                        ),
                        child: QrImageView(
                          data: widget.guest['qr_token'] as String,
                          size: 170,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: ink,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invitation #INV-${widget.guest['id'].toString().padLeft(5, '0')}',
                        style: const TextStyle(
                          color: Color(0xFF806E60),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _goldDivider(primary),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _InvitationDetail(
                              icon: Icons.calendar_month_outlined,
                              value: _invitationDate(date),
                            ),
                          ),
                          Container(width: 1, height: 52, color: primary),
                          Expanded(
                            child: _InvitationDetail(
                              icon: Icons.location_on_outlined,
                              value: _joinInvitationDetails([venue, address]),
                            ),
                          ),
                        ],
                      ),
                      if (category.isNotEmpty ||
                          guestCount.isNotEmpty ||
                          table.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _InvitationDetail(
                                icon: Icons.people_outline,
                                value: _joinInvitationDetails([
                                  category,
                                  guestCount.isEmpty
                                      ? null
                                      : '$guestCount personne(s)',
                                ]),
                              ),
                            ),
                            if (table.isNotEmpty) ...[
                              Container(width: 1, height: 42, color: primary),
                              Expanded(
                                child: _InvitationDetail(
                                  icon: Icons.table_restaurant_outlined,
                                  value: 'Table\n$table',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String firstName, String secondName) {
  final first = firstName.trim().isEmpty ? 'M' : firstName.trim()[0];
  final second = secondName.trim().isEmpty ? 'M' : secondName.trim()[0];
  return '$first & $second';
}

Widget _goldDivider([Color color = const Color(0xFFC99643)]) {
  return Row(
    children: [
      Expanded(child: Divider(color: color.withValues(alpha: .55))),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.diamond, color: color, size: 12),
      ),
      Expanded(child: Divider(color: color.withValues(alpha: .55))),
    ],
  );
}

class _InvitationDetail extends StatelessWidget {
  const _InvitationDetail({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC99643), size: 25),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF5C4431),
            fontSize: 13,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({
    required this.token,
    required this.eventId,
    super.key,
  });
  final String token;
  final int eventId;

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<dynamic> scans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await Dio().get(
        '${appConfig.apiBaseUrl}/events/${widget.eventId}/scans?per_page=50',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      if (mounted) {
        setState(
          () => scans = List<dynamic>.from(
            (response.data as Map)['data'] as List,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des entrées')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: champagne))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = Map<String, dynamic>.from(scans[index] as Map);
                  final guest = scan['guest'] as Map<String, dynamic>?;
                  final valid = scan['status'] == 'valid';
                  return Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: .72),
                    child: ListTile(
                      leading: Icon(
                        valid
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: valid ? Colors.green : champagne,
                      ),
                      title: Text(
                        guest == null
                            ? 'QR inconnu'
                            : '${guest['first_name']} ${guest['last_name']}',
                        style: const TextStyle(color: ink),
                      ),
                      subtitle: Text(
                        scan['status'].toString().replaceAll('_', ' '),
                        style: const TextStyle(color: Color(0xFF806E60)),
                      ),
                      trailing: Text(
                        scan['scanned_at']
                            .toString()
                            .split('T')
                            .last
                            .split('.')
                            .first,
                        style: const TextStyle(color: Color(0xFF806E60)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
