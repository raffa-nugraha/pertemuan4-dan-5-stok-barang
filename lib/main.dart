import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pencatatan Stok Barang',
      theme: AppTheme.lightTheme,
      home: const StokBarangPage(),
    );
  }
}

class StokBarangPage extends StatefulWidget {
  const StokBarangPage({super.key});

  @override
  State<StokBarangPage> createState() => _StokBarangPageState();
}

class _StokBarangPageState extends State<StokBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Controllers untuk input
  final TextEditingController _namaBarangController =
  TextEditingController(text: 'R'); // Default inisial Raffa
  final TextEditingController _tanggalMasukController = TextEditingController();
  final TextEditingController _tanggalKeluarController = TextEditingController();
  final TextEditingController _kodeBarangController = TextEditingController();
  final TextEditingController _jumlahStokController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _namaBarangController.dispose();
    _tanggalMasukController.dispose();
    _tanggalKeluarController.dispose();
    _kodeBarangController.dispose();
    _jumlahStokController.dispose();
    super.dispose();
  }

  // Validasi Kode Barang (minimal 6 angka, harus berakhir dengan 123)
  String? _validateKodeBarang(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode Barang harus diisi';
    }

    // Cek apakah hanya angka
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Kode Barang hanya boleh berupa angka';
    }

    // Cek apakah minimal 6 digit
    if (value.length < 6) {
      return 'Kode Barang minimal 6 angka';
    }

    // Cek apakah berakhir dengan 123 (3 angka terakhir NIM)
    if (!value.endsWith('123')) {
      return 'Kode Barang harus berakhir dengan 123';
    }

    return null;
  }

  // Validasi Jumlah Stok (integer, tidak negatif)
  String? _validateJumlahStok(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah Stok harus diisi';
    }
    final int? stok = int.tryParse(value);
    if (stok == null) {
      return 'Jumlah Stok harus berupa angka bulat';
    }
    if (stok < 0) {
      return 'Jumlah Stok tidak boleh negatif';
    }
    return null;
  }

  // Validasi Tanggal (format: 16-10-2026)
  String? _validateTanggal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal harus diisi';
    }
    // Cek format dd-mm-yyyy
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
      return 'Format tanggal: dd-mm-yyyy (contoh: 16-10-2026)';
    }
    return null;
  }

  // Fungsi simpan ke Firestore
  Future<void> _simpanBarang() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse data
      String namaBarang = _namaBarangController.text.trim();
      String tanggalMasuk = _tanggalMasukController.text.trim();
      String tanggalKeluar = _tanggalKeluarController.text.trim();
      int kodeBarang = int.parse(_kodeBarangController.text.trim());
      int jumlahStok = int.parse(_jumlahStokController.text.trim());

      // Simpan ke Firestore
      await _firestore.collection('stok_barang').add({
        'nama_barang': namaBarang,
        'tanggal_masuk': tanggalMasuk,
        'tanggal_keluar': tanggalKeluar,
        'kode_barang': kodeBarang,
        'jumlah_stok': jumlahStok,
        'waktu': FieldValue.serverTimestamp(),
      });

      // Success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data barang berhasil disimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset form (Nama Barang tetap "R")
        _namaBarangController.text = 'R';
        _tanggalMasukController.clear();
        _tanggalKeluarController.clear();
        _kodeBarangController.clear();
        _jumlahStokController.clear();
        _formKey.currentState?.reset();
      }
    } catch (e) {
      // Error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Stok Barang'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(19.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Nama Barang (default: R)
                    TextFormField(
                      controller: _namaBarangController,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        hintText: 'Inisial: R',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.inventory),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama Barang harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Tanggal Masuk Barang (text manual)
                    TextFormField(
                      controller: _tanggalMasukController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Masuk',
                        hintText: 'dd-mm-yyyy (contoh: 16-10-2026)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: _validateTanggal,
                    ),
                    const SizedBox(height: 16),

                    // 3. Tanggal Keluar Barang (text manual)
                    TextFormField(
                      controller: _tanggalKeluarController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Keluar',
                        hintText: 'dd-mm-yyyy (contoh: 16-10-2026)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: _validateTanggal,
                    ),
                    const SizedBox(height: 16),

                    // 4. Kode Barang (minimal 6 angka, harus berakhir 123)
                    TextFormField(
                      controller: _kodeBarangController,
                      decoration: InputDecoration(
                        labelText: 'Kode Barang',
                        hintText:
                        'Minimal 6 angka, harus berakhir 123 (contoh: 100123)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateKodeBarang,
                    ),
                    const SizedBox(height: 16),

                    // 5. Jumlah Stok (integer, tidak negatif)
                    TextFormField(
                      controller: _jumlahStokController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Stok',
                        hintText: 'Contoh: 50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.production_quantity_limits),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateJumlahStok,
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      height: 43.0,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _simpanBarang,
                        icon: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Barang'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}