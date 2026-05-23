/// Repository of Doas for sacred zones in Makkah and Madinah
/// Contains Arabic text, Latin transliteration, and Indonesian translation

class DoaRepository {
  static final DoaRepository _instance = DoaRepository._internal();
  static DoaRepository get instance => _instance;
  DoaRepository._internal();

  /// Get doa for a specific zone
  String? getDoaForZone(String zoneId) {
    return _doas[zoneId]?.toString();
  }

  /// Get all available zones
  List<Map<String, dynamic>> getAllZones() {
    return _zones.entries.map((e) => <String, dynamic>{
      'id': e.key,
      'name': e.value['name'] as String,
      'arabic': e.value['arabic'] as String,
      'description': e.value['description'] as String,
    }).toList();
  }

  /// Get full doa data for a zone
  Map<String, dynamic>? getDoaData(String zoneId) {
    return _doas[zoneId];
  }

  /// Sacred zones with their prayers
  static const Map<String, Map<String, dynamic>> _doas = {
    'kabah': {
      'name': 'Ka\'bah',
      'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
      'latin': 'Allahumma inni as-alukal afwa wal afiyah fi dunya wal akhiroh',
      'indonesian': 'Ya Allah, aku memohon ampunan dan kesehatan di dunia dan akhirat',
      'description': 'Doa saat melihat Ka\'bah atau melakukan tawaf',
    },
    'maqam_ibrahim': {
      'name': 'Maqam Ibrahim',
      'arabic': 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ',
      'latin': 'Rabbij\'alni muqimas salati wa min dzurriyyati rabbana wa taqabbal duaa\'',
      'indonesian': 'Ya Tuhanku, jadikanlah aku dan anak cucuku orang yang mendirikan shalat',
      'description': 'Doa saat mengerjakan shalat di belakang Maqam Ibrahim',
    },
    'zamzam': {
      'name': 'Bikmat Zamzam',
      'arabic': 'بِسْمِ اللَّهِ وَالْحَمْدُ لِلَّهِ وَصَلَّى اللَّهُ عَلَى رَسُولِ اللَّهِ',
      'latin': 'Bismillah walhamdulillah washallallahu alaa rasulillah',
      'indonesian': 'Dengan nama Allah, segala puji bagi Allah, shalawat kepada Rasulullah',
      'description': 'Doa saat minum air Zamzam',
    },
    'safaa_marwa': {
      'name': 'Safa dan Marwa',
      'arabic': 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ',
      'latin': 'Innass safa wal marwata min sya\'airillah',
      'indonesian': 'Sesungguhnya Safa dan Marwa adalah sebagian dari rites Allah',
      'description': 'Doa saat melakukan sai antara Safa dan Marwa',
    },
    'raudhah': {
      'name': 'Raudhah',
      'arabic': 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ الْأَرْحَمُ الرَّاحِمِينَ',
      'latin': 'Rabbigfir warham wa anta arhamar rohimin',
      'indonesian': 'Ya Tuhanku, ampunilah dan rahmatilah, Engkau yang paling penyayang',
      'description': 'Doa di Raudhah Jardin Masjid Nabawi',
    },
    'rawdah': {
      'name': 'Raudhah',
      'arabic': 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ الْأَعَزُّ الْأَكْرَمُ',
      'latin': 'Rabbigfir warham wa anta al-a\'azzul akrom',
      'indonesian': 'Ya Tuhanku, ampunilah dan rahmatilah, Engkau yang paling mulia',
      'description': 'Doa di Raudhah Masjid Nabawi',
    },
    'qiblatain': {
      'name': 'Masjid Qiblatain',
      'arabic': 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً',
      'latin': 'Rabbana laa tuzig qulubana ba\'da idz hadaitana wa hab lana min ladunka rahmah',
      'indonesian': 'Ya Tuhan kami, janganlah Engkau Devatkan hati kami setelah Engkau beri petunjuk',
      'description': 'Doa saat shalat di Masjid Qiblatain',
    },
    'uhud': {
      'name': 'Gunung Uhud',
      'arabic': 'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
      'latin': 'Allahumma laa sahla illaa ma ja\'altahu sahlan wa anta taj\'alul hazna idza syi\'ta sahlan',
      'indonesian': 'Ya Allah, tidak ada kemudahan kecuali apa yang Engkau buat mudah',
      'description': 'Doa di Gunung Uhud sebagai penghormatan kepada syuhada',
    },
  };

  /// Zone definitions with coordinates
  static const Map<String, Map<String, dynamic>> _zones = {
    'kabah': {
      'name': 'Ka\'bah',
      'arabic': 'الكعبة',
      'lat': 21.4225,
      'lng': 39.8262,
      'radius': 100, // meters
      'mosque': 'Masjidil Haram',
      'description': 'Pusat Masjidil Haram, lokasi Ka\'bah yang diagungkan',
    },
    'maqam_ibrahim': {
      'name': 'Maqam Ibrahim',
      'arabic': 'مقام إبراهيم',
      'lat': 21.4220,
      'lng': 39.8258,
      'radius': 20,
      'mosque': 'Masjidil Haram',
      'description': 'Lokasi berdiri Nabi Ibrahim saat membangun Ka\'bah',
    },
    'zamzam': {
      'name': 'Bikmat Zamzam',
      'arabic': 'بئر زمزم',
      'lat': 21.4223,
      'lng': 39.8267,
      'radius': 30,
      'mosque': 'Masjidil Haram',
      'description': 'Sumur Zamzam di dalam Masjidil Haram',
    },
    'safaa': {
      'name': 'Safa',
      'arabic': 'صفا',
      'lat': 21.4205,
      'lng': 39.8275,
      'radius': 50,
      'mosque': 'Masjidil Haram',
      'description': 'Bukit Safa, awal sai',
    },
    'marwa': {
      'name': 'Marwa',
      'arabic': 'مروة',
      'lat': 21.4195,
      'lng': 39.8285,
      'radius': 50,
      'mosque': 'Masjidil Haram',
      'description': 'Bukit Marwa, akhir sai',
    },
    'raudhah': {
      'name': 'Raudhah',
      'arabic': 'الروضة',
      'lat': 24.4672,
      'lng': 39.6110,
      'radius': 50,
      'mosque': 'Masjid Nabawi',
      'description': 'Taman surgawi antara mimbar dan Ka\'bah Nabawi',
    },
    'rawdah': {
      'name': 'Rawdah',
      'arabic': 'الروضة',
      'lat': 24.4672,
      'lng': 39.6110,
      'radius': 50,
      'mosque': 'Masjid Nabawi',
      'description': 'Sinonim untuk Raudhah - taman di dalam Masjid Nabawi',
    },
    'qiblatain': {
      'name': 'Masjid Qiblatain',
      'arabic': 'مسجد القبلتين',
      'lat': 24.4814,
      'lng': 39.5854,
      'radius': 100,
      'mosque': 'Masjid Qiblatain',
      'description': 'Masjid tempat perintah shalat menghadap ke Masjidil Aqsa diubah menjadi Ka\'bah',
    },
    'uhud': {
      'name': 'Masjid Uhud',
      'arabic': 'مسجد أحد',
      'lat': 24.4888,
      'lng': 39.5720,
      'radius': 200,
      'mosque': 'Masjid Uhud',
      'description': 'Lokasi perang Uhud dan makam para syuhada',
    },
  };

  /// Check if coordinates are within a zone
  String? detectZone(double lat, double lng) {
    for (final entry in _zones.entries) {
      final zone = entry.value;
      final zoneLat = zone['lat'] as double;
      final zoneLng = zone['lng'] as double;
      final radius = zone['radius'] as int;

      final distance = _calculateDistance(lat, lng, zoneLat, zoneLng);
      if (distance <= radius) {
        return entry.key;
      }
    }
    return null;
  }

  /// Haversine distance calculation
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = 
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 3.141592653589793 / 2);
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  double _atan(double x) {
    // Taylor series approximation for small x
    if (x.abs() < 1) {
      double result = x;
      double term = x;
      for (int n = 1; n < 10; n++) {
        term *= -x * x;
        result += term / (2 * n + 1);
      }
      return result;
    }
    return 3.141592653589793 / 2 - _atan(1 / x);
  }
  double _taylorSin(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    while (x < -3.141592653589793) x += 2 * 3.141592653589793;
    double result = x;
    double term = x;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }
}
