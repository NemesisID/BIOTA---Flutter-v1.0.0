import 'package:flutter/material.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  String _userName = "Adi"; // Data dummy untuk username
  List<Map<String, dynamic>> _speciesData = []; // List untuk menyimpan data spesies

  @override
  void initState() {
    super.initState();
    _loadSpeciesData(); // Panggil method untuk memuat data spesies
  }

  // Method untuk memuat data spesies (dummy atau dari database lokal)
  Future<void> _loadSpeciesData() async {
    // TODO: Ganti dengan logika pengambilan data dari database lokal
    // Untuk saat ini, kita gunakan data dummy
    setState(() {
      _speciesData = [
        {
          'imageUrl': 'https://via.placeholder.com/120/FF5733/FFFFFF?Text=Species1',
          'name': 'Cendrawasih Merah',
          'latinName': 'Paradisaea rubra',
          'status': 'Terancam Punah',
          'funFact': 'Dikenal karena bulu merahnya yang indah.'
        },
        {
          'imageUrl': 'https://via.placeholder.com/120/3498DB/FFFFFF?Text=Species2',
          'name': 'Harimau Sumatra',
          'latinName': 'Panthera tigris sumatrae',
          'status': 'Kritis',
          'funFact': 'Satu-satunya subspesies harimau yang masih bertahan di Indonesia.'
        },
        {
          'imageUrl': 'https://via.placeholder.com/120/2ECC71/FFFFFF?Text=Species3',
          'name': 'Orangutan Kalimantan',
          'latinName': 'Pongo pygmaeus',
          'status': 'Kritis',
          'funFact': 'Primata arboreal terbesar di Asia.'
        },
        // Tambahkan data spesies lain di sini jika diperlukan
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Atas: Salam, Nama User, dan Ikon Notifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $_userName',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Jelajahi & Lindungi Flora & Fauna di Sekitarmu',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none_outlined), // Ganti dengan ikon notifikasi yang sesuai
                    onPressed: () {
                      // Aksi ketika ikon notifikasi ditekan
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Bagian Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari berita, spesies, atau event',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) {
                  // Logika untuk search (sementara dummy)
                },
              ),
              SizedBox(height: 20),

              // Bagian Berita Alam Hari Ini
              Text(
                'Berita Alam Hari Ini!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 200, // Sesuaikan tinggi container berita
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5, // Jumlah berita dummy
                  itemBuilder: (context, index) {
                    // Data dummy untuk berita
                    String dummyImageUrl = 'https://via.placeholder.com/150/771796'; // Ganti dengan URL gambar yang valid atau path aset
                    String dummyTitle = 'Tumbuhan Hutan Pulih di Musim Hujan ${index + 1}';
                    String dummySource = 'WWF Indonesia';
                    String dummyTime = '${index + 2} jam yang lalu';

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(right: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Container(
                        width: 250, // Lebar kartu berita
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
                              child: Image.network( // Gunakan Image.asset jika gambar dari lokal
                                dummyImageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: Center(child: Icon(Icons.image_not_supported, color: Colors.grey[600])),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Tambahkan ini agar Column tidak mengambil ruang berlebih
                                children: [
                                  Text(
                                    dummyTitle,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), // Sedikit kurangi ukuran font jika perlu
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2), // Kurangi spasi jika perlu
                                  Text(
                                    '$dummySource - $dummyTime',
                                    style: TextStyle(fontSize: 9, color: Colors.grey[600]), // Sedikit kurangi ukuran font jika perlu
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0, bottom: 4.0), // Sesuaikan padding tombol
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero, // Hapus padding internal TextButton jika perlu
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Kurangi area tap jika perlu
                                  ),
                                  onPressed: () {
                                    // Aksi ketika tombol "Lihat Ceritanya" ditekan
                                  },
                                  child: Text('Lihat Ceritanya', style: TextStyle(fontSize: 12)), // Sesuaikan ukuran font tombol
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Bagian Berita Ceria Hari Ini
              Text(
                'Berita Ceria Hari Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.green[100], // Warna latar belakang kartu
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Icon (misalnya paus biru)
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[300], // Warna background ikon
                        child: Icon(Icons.water, size: 30, color: Colors.white), // Ganti dengan ikon yang sesuai
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paus Biru Kembali ke Laut Indonesia!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Setelah bertahun-tahun menghilang, paus biru terlihat berenang di perairan kita lagi!',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Bagian Keanekaragaman Hayati
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Tambahkan Expanded di sini
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keanekaragaman Hayati',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Kenali, sayangi, dan selamatkan mereka sebelum terlambat.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Aksi ketika tombol "Lihat Semua" ditekan
                    },
                    child: Text('Lihat Semua'),
                  )
                ],
              ),
              SizedBox(height: 10),
              // Filter Buttons
              SingleChildScrollView( // Bungkus Row dengan SingleChildScrollView
                scrollDirection: Axis.horizontal,
                child: Row(
                  // MainAxisAlignment.spaceAround, // Hapus atau sesuaikan jika menggunakan SingleChildScrollView
                  children: [
                    ElevatedButton(onPressed: () {}, child: Text('Semua'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white)),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Rentan Kepunahan')),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Terancam Punah')),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Punah')),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 220, // Sesuaikan tinggi container spesies
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _speciesData.length, // Gunakan panjang list _speciesData
                  itemBuilder: (context, index) {
                    // Ambil data dari _speciesData
                    final species = _speciesData[index];
                    String dummySpeciesImageUrl = species['imageUrl'] ?? 'https://via.placeholder.com/120/CCCCCC/FFFFFF?Text=NoImage';
                    String dummySpeciesName = species['name'] ?? 'Nama Spesies';
                    String dummyLatinName = species['latinName'] ?? 'Nama Latin';
                    String dummyStatus = species['status'] ?? 'Status Tidak Diketahui';
                    String funFact = species['funFact'] ?? 'Fakta menarik tidak tersedia.';

                    Color statusColor = Colors.grey; // Warna default
                    if (dummyStatus == 'Terancam Punah') statusColor = Colors.orange;
                    if (dummyStatus == 'Rentan Kepunahan') statusColor = Colors.yellow[700]!;
                    if (dummyStatus == 'Punah') statusColor = Colors.red;
                    if (dummyStatus == 'Kritis') statusColor = Colors.red[900]!;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(right: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.lightGreen[50], // Warna latar kartu spesies
                      child: Container(
                        width: 150, // Lebar kartu spesies
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(dummySpeciesImageUrl),
                              backgroundColor: Colors.grey[200],
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading image: $exception');
                              },
                              child: dummySpeciesImageUrl.isEmpty || dummySpeciesImageUrl.contains('placeholder') || dummySpeciesImageUrl.contains('NoImage')
                                  ? Icon(Icons.eco, size: 30, color: Colors.green[700])
                                  : null,
                            ),
                            SizedBox(height: 8),
                            Text(dummySpeciesName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,),
                            Text(dummyLatinName, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[600]), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(dummyStatus, style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(height: 5),
                            Text(
                              funFact, // Gunakan funFact dari data
                              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton(onPressed: () {}, child: Text('Pelajari', style: TextStyle(fontSize: 11))),
                                TextButton(onPressed: () {}, child: Text('Habitat', style: TextStyle(fontSize: 11))),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Bagian Event Volunteer Alam
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Volunteer Alam',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Siap untuk petualangan konservasi minggu ini?',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Aksi ketika tombol "Lihat Semua" ditekan
                    },
                    child: Text('Lihat Semua'),
                  )
                ],
              ),
              SizedBox(height: 10),
              // Filter Buttons (jika diperlukan, bisa disesuaikan atau dihilangkan)
              SingleChildScrollView( // Bungkus Row dengan SingleChildScrollView
                scrollDirection: Axis.horizontal,
                child: Row(
                  // MainAxisAlignment.spaceAround, // Hapus atau sesuaikan jika menggunakan SingleChildScrollView
                  children: [
                    ElevatedButton(onPressed: () {}, child: Text('Semua'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white)),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Pemula')),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Tingkat Dasar')),
                    SizedBox(width: 8), // Tambahkan SizedBox untuk spasi antar tombol
                    OutlinedButton(onPressed: () {}, child: Text('Tingkat Lanjut')),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 280, // Sesuaikan tinggi container event
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3, // Jumlah event dummy
                  itemBuilder: (context, index) {
                    // Data dummy untuk event
                    String dummyEventImageUrl = 'https://via.placeholder.com/200x120/4CAF50/FFFFFF?Text=Event${index+1}'; // Ganti dengan URL gambar yang valid atau path aset
                    String dummyEventTitle = 'Ayo Tanam Pohon di Taman Kota! ${index + 1}';
                    String dummyEventDate = '15 April 2024';
                    String dummyEventLocation = 'Taman Flora, Surabaya';
                    String dummyEventLevel = 'Pemula';
                    int dummyParticipants = 9 + index;

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(right: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Container(
                        width: 280, // Lebar kartu event
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
                              child: Image.network(
                                dummyEventImageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: Center(child: Icon(Icons.event_busy, color: Colors.grey[600])),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dummyEventTitle,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[700]),
                                      SizedBox(width: 5),
                                      Text(dummyEventDate, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(dummyEventLocation, style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis, maxLines: 1,)
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.teal[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(dummyEventLevel, style: TextStyle(fontSize: 10, color: Colors.teal[800], fontWeight: FontWeight.bold)),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.group, size: 16, color: Colors.grey[700]),
                                          SizedBox(width: 4),
                                          Text('+$dummyParticipants', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}