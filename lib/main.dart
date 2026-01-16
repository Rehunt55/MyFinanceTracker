import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
// ignore: unused_import
import 'package:xml/xml.dart' as xml;
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'gemini_service.dart'; // Asistan servisi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyFinanceTracker());
}

class MyFinanceTracker extends StatefulWidget {
  const MyFinanceTracker({super.key});
  @override
  State<MyFinanceTracker> createState() => _MyFinanceTrackerState();
}

class _MyFinanceTrackerState extends State<MyFinanceTracker> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDark
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF010203),
              primaryColor: const Color(0xFF00FFD1),
              cardColor: const Color(0xFF0D0E10),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            )
          : ThemeData.light().copyWith(primaryColor: const Color(0xFF009688)),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return MainInterface(
              onThemeToggle: () => setState(() => _isDark = !_isDark),
              isDark: _isDark,
            );
          }
          return const AuthPortal();
        },
      ),
    );
  }
}

// --- VERİ MODELİ ---
class AssetModel {
  final String id, name, category;
  final double amount, price;
  AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.price,
  });
  double get total => amount * price;
}

// --- GİRİŞ & KAYIT ---
class AuthPortal extends StatefulWidget {
  const AuthPortal({super.key});
  @override
  State<AuthPortal> createState() => _AuthPortalState();
}

class _AuthPortalState extends State<AuthPortal> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true, _obs = true, _load = false;

  void _showMsg(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  Future<void> _authAction() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _showMsg("Lütfen alanları doldurun!");
      return;
    }
    setState(() => _load = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );
      }
    } catch (e) {
      _showMsg("Hata: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.rocket_launch,
                size: 80,
                color: Color(0xFF00FFD1),
              ),
              const SizedBox(height: 12),
              const Text(
                "My Finance Tracker",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  hintText: "E-POSTA",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: _obs,
                decoration: InputDecoration(
                  hintText: "ŞİFRE",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obs ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obs = !_obs),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _load
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _authAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFD1),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: Text(
                        _isLogin ? "GİRİŞ YAP" : "KAYIT OL",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Hala kayıt olmadın mı?" : "Zaten hesabım var mı?",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ANA PANEL ---
class MainInterface extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDark;
  const MainInterface({
    super.key,
    required this.onThemeToggle,
    required this.isDark,
  });
  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ignore: prefer_final_fields
  Map<String, double> _p = {
    "USD": 36.55,
    "GRAM": 3185.0,
    "CEYREK": 5220.0,
    "BTC": 3310000.0,
    "THYAO": 288.0,
    "EUR": 38.50,
  };

  // ignore: prefer_final_fields
  List<Map<String, String>> _news = [];
  bool _hide = false, _aiLoading = false;
  final _aiController = TextEditingController();
  String _aiResponse = "Bugün nasıl yardımcı olabilirim?";

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _syncData();
  }

  Future<void> _syncData() async {
    if (!mounted) return;
    setState(() {
      _aiLoading = true;
    });

    const String apiKey = "4Qyk0EzVKXFsjZ4uNmBVvr:5t1zqSQIgRQV7o3OZKW2Gp";

    final headers = {
      'content-type': 'application/json',
      'authorization': 'apikey $apiKey',
    };

    try {
      // 1. CANLI ALTIN VERİLERİ
      final goldRes = await http.get(
        Uri.parse('https://api.collectapi.com/economy/goldPrice'),
        headers: headers,
      );

      // 2. CANLI DÖVİZ VERİLERİ
      final currencyRes = await http.get(
        Uri.parse('https://api.collectapi.com/economy/allCurrency'),
        headers: headers,
      );

      // 3. CANLI BORSA İSTANBUL (Hisseler)
      final borsaRes = await http.get(
        Uri.parse('https://api.collectapi.com/economy/hisseSenedi'),
        headers: headers,
      );

      // 4. KRİPTO VERİLERİ (Ücretsiz ve stabil kaynak)
      final btcRes = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana,avalanche-2&vs_currencies=try',
        ),
      );

      if (mounted) {
        setState(() {
          // ALTIN GÜNCELLEME
          if (goldRes.statusCode == 200) {
            final goldList = json.decode(goldRes.body)['result'] as List;
            for (var item in goldList) {
              double val =
                  double.tryParse(
                    item['selling'].toString().replaceAll(',', '.'),
                  ) ??
                  0.0;
              if (item['name'] == "Gram Altın") _p["GRAM"] = val;
              if (item['name'] == "Çeyrek Altın") _p["CEYREK"] = val;
              if (item['name'] == "Tam Altın") _p["TAM"] = val;
              if (item['name'] == "Ons Altın") _p["ONS"] = val;
            }
          }

          // DÖVİZ GÜNCELLEME
          if (currencyRes.statusCode == 200) {
            final currList = json.decode(currencyRes.body)['result'] as List;
            for (var item in currList) {
              double val =
                  double.tryParse(
                    item['selling'].toString().replaceAll(',', '.'),
                  ) ??
                  0.0;
              if (item['name'] == "ABD Doları") _p["USD"] = val;
              if (item['name'] == "Euro") _p["EUR"] = val;
              if (item['name'] == "İngiliz Sterlini") _p["GBP"] = val;
            }
          }

          // BORSA GÜNCELLEME
          if (borsaRes.statusCode == 200) {
            final borsaList = json.decode(borsaRes.body)['result'] as List;
            for (var item in borsaList) {
              _p[item['code']] =
                  double.tryParse(
                    item['lastprice'].toString().replaceAll(',', '.'),
                  ) ??
                  0.0;
            }
          }

          // KRİPTO GÜNCELLEME
          if (btcRes.statusCode == 200) {
            var c = json.decode(btcRes.body);
            _p["BTC"] = c['bitcoin']['try'].toDouble();
            _p["ETH"] = c['ethereum']['try'].toDouble();
            _p["SOL"] = c['solana']['try'].toDouble();
            _p["AVAX"] = c['avalanche-2']['try'].toDouble();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Tüm veriler (Altın, Döviz, Borsa, Kripto) güncellendi!",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bağlantı hatası: API anahtarını kontrol edin."),
          ),
        );
      }
    } finally {
      if (mounted)
        // ignore: curly_braces_in_flow_control_structures
        setState(() {
          _aiLoading = false;
        });
    }
  }

  // AI
  void _handleAi() async {
    if (_aiController.text.isEmpty) return;
    setState(() {
      _aiLoading = true;
      _aiResponse = "Hesaplanıyor...";
    });

    final res = await GeminiService().askAi(_aiController.text);

    if (res["data"] != null) {
      final data = res["data"];
      String name = data["ad"].toString().toUpperCase();
      String cat = _detectCategory(name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .collection('assets')
          .add({
            'name': name,
            'category': cat,
            'amount': double.tryParse(data['miktar'].toString()) ?? 0.0,
          });
      _aiController.clear();
    }

    setState(() {
      _aiResponse = res["text"];
      _aiLoading = false;
    });
  }

  String _detectCategory(String name) {
    if (["BTC", "ETH", "SOL", "AVAX"].contains(name)) return "kripto";
    if (["USD", "EUR", "GBP"].contains(name)) return "doviz";
    if (["GRAM", "CEYREK", "ONS"].contains(name)) return "altin";
    return "borsa";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Finance Tracker",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF00FFD1),
          ),
        ),
        actions: [
          //GÜNCELLEME BUTONU
          IconButton(
            icon: _aiLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00FFD1),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _syncData,
            tooltip: "Verileri Güncelle",
          ),
          // -----------------------------------------
          IconButton(
            icon: Icon(widget.isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(
            icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hide = !_hide),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: "ANALİZ"),
            Tab(text: "BORSA"),
            Tab(text: "KRİPTO"),
            Tab(text: "DÖVİZ"),
            Tab(text: "ALTIN"),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.email)
            .collection('assets')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            // ignore: curly_braces_in_flow_control_structures
            return const Center(child: CircularProgressIndicator());
          var items = snapshot.data!.docs
              .map(
                (d) => AssetModel(
                  id: d.id,
                  name: d['name'],
                  amount: d['amount'].toDouble(),
                  category: d['category'],
                  price: _p[d['name']] ?? 1.0,
                ),
              )
              .toList();
          // ignore: avoid_types_as_parameter_names
          double tl = items.fold(0, (sum, e) => sum + e.total);
          return TabBarView(
            controller: _tabs,
            children: [
              _buildAnaliz(tl, items),
              _buildList(items, "borsa"),
              _buildList(items, "kripto"),
              _buildList(items, "doviz"),
              _buildList(items, "altin"),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _manageAsset(),
        backgroundColor: const Color(0xFF00FFD1),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildAnaliz(double tl, List<AssetModel> items) {
    double totalTl = 0;

    for (var item in items) {
      double price = _p[item.name] ?? 0.0;
      totalTl += item.amount * price;
    }

    double usdRate = _p["USD"] ?? 36.55;
    double totalUsd = totalTl / usdRate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ignore: avoid_unnecessary_containers
          Container(
            child: Column(
              children: [
                const Text("NET VARLIK DEĞERİ"),
                const SizedBox(height: 8),

                Text(
                  _hide ? "₺ •••••" : "₺${totalTl.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _hide ? "\$ •••••" : "\$${totalUsd.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFF00FFD1),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // ASİSTAN PANELİ
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00FFD1),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "YAPAY ZEKA ASİSTANI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (_aiLoading)
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aiResponse,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                TextField(
                  controller: _aiController,
                  decoration: InputDecoration(
                    hintText: "Örn: 50 adet THYAO ekle",
                    hintStyle: const TextStyle(fontSize: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: _handleAi,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (items.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "VARLIK DAĞILIMI",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: _getSections(items))),
            ),
          ],
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "SON HABERLER",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const Divider(),
          ..._news
              .take(5)
              .map(
                (n) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: 16,
                  ),
                  title: Text(n['t']!, style: const TextStyle(fontSize: 13)),
                  onTap: () => launchUrl(Uri.parse(n['l']!)),
                ),
              ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections(List<AssetModel> items) {
    Map<String, double> catMap = {};
    for (var e in items)
      // ignore: curly_braces_in_flow_control_structures
      catMap[e.category] = (catMap[e.category] ?? 0) + e.total;
    return catMap.entries
        .map(
          (e) => PieChartSectionData(
            value: e.value,
            title: e.key.toUpperCase(),
            color: Colors.primaries[catMap.keys.toList().indexOf(e.key) % 15],
            radius: 55,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
        .toList();
  }

  Widget _buildList(List<AssetModel> items, String cat) {
    var filtered = items.where((e) => e.category == cat).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          title: Text(
            filtered[i].name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${filtered[i].amount} Adet"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _hide
                        ? "₺ •••"
                        : "₺${filtered[i].total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _hide
                        ? "\$ •••"
                        : "\$${(filtered[i].total / _p["USD"]!).toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Color(0xFF00FFD1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.blueAccent,
                ),
                onPressed: () => _manageAsset(item: filtered[i]),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: () => _deleteAsset(filtered[i].id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manageAsset({AssetModel? item}) {
    String selCat = item?.category ?? "borsa", selName = item?.name ?? "THYAO";
    final amtCtrl = TextEditingController(text: item?.amount.toString() ?? "");
    Map<String, List<String>> opts = {
      "borsa": ["THYAO", "EREGL", "ASELS", "SASA"],
      "kripto": ["BTC", "ETH", "SOL", "AVAX"],
      "doviz": ["USD", "EUR", "GBP"],
      "altin": ["GRAM", "CEYREK", "ONS"],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setUI) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item == null ? "YENİ VARLIK EKLE" : "VARLIĞI GÜNCELLE",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FFD1),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selCat,
                items: opts.keys
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(k.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setUI(() {
                  selCat = v!;
                  selName = opts[v]!.first;
                }),
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selName,
                items: opts[selCat]!
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setUI(() => selName = v!),
                decoration: const InputDecoration(labelText: "Varlık"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Miktar (Adet/Birim)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final ref = FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.email)
                      .collection('assets');
                  final data = {
                    'name': selName,
                    'category': selCat,
                    'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                  };
                  item == null ? ref.add(data) : ref.doc(item.id).update(data);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF00FFD1),
                  foregroundColor: Colors.black,
                ),
                child: const Text("SİSTEME KAYDET"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAsset(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Varlığı Sil?"),
        content: const Text("Bu işlem geri alınamaz. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İPTAL"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.email)
                  .collection('assets')
                  .doc(id)
                  .delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }
}
