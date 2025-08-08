import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'recycling_data.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(title: 'District Recycling', home: MainTabView());
  }
}

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DistrictListScreen(),
    MaterialListScreen(),
    PhotoCaptureScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics:
                  const BouncingScrollPhysics(), // iOS-style bounce physics
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _pages[index];
              },
            ),
          ),
          CupertinoTabBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.mapLocationDot, size: 20),
                label: 'Districts',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.recycle, size: 20),
                label: 'Materials',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.camera, size: 20),
                label: 'Photo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DistrictListScreen extends StatefulWidget {
  const DistrictListScreen({super.key});

  @override
  State<DistrictListScreen> createState() => _DistrictListScreenState();
}

class _DistrictListScreenState extends State<DistrictListScreen> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DistrictRecycling> _filteredDistricts = recyclingData;
  String _locationStatus = 'Getting your location...';
  String? _nearestDistrict;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  bool _isShakeDetected = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation();
    _initializeShakeDetection();
  }

  void _initializeShakeDetection() {
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 15.0 && !_isShakeDetected) {
        _isShakeDetected = true;
        _handleShakeGesture();
        Timer(const Duration(seconds: 2), () {
          _isShakeDetected = false;
        });
      }
    });
  }

  void _handleShakeGesture() {
    // Shake to refresh location and find nearest district
    _getCurrentLocation();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Shake Detected!'),
              content: const Text(
                'Refreshing your location and finding nearby districts...',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission permanently denied';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _locationStatus = 'Location found';
        _nearestDistrict = _findNearestFictionalDistrict(position);
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: ${e.toString()}';
      });
    }
  }

  String _findNearestFictionalDistrict(Position position) {
    // Create fictional coordinates for our districts and find the "nearest" one
    final Random random = Random(
      position.latitude.hashCode + position.longitude.hashCode,
    );
    final availableDistricts = recyclingData.map((d) => d.district).toList();
    return availableDistricts[random.nextInt(availableDistricts.length)];
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDistricts = recyclingData;
      } else {
        _filteredDistricts =
            recyclingData
                .where((d) => d.district.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _showAndFocusSearchBar() {
    setState(() {
      _showSearch = true;
    });
    Future.delayed(Duration.zero, () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle:
            _showSearch
                ? CupertinoSearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  placeholder: 'Search for a district...',
                )
                : const Text('Districts'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _showSearch ? CupertinoIcons.clear : CupertinoIcons.search,
          ),
          onPressed: () {
            if (_showSearch) {
              setState(() {
                _showSearch = false;
                _searchController.clear();
              });
            } else {
              _showAndFocusSearchBar();
            }
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Location status header
            if (_nearestDistrict != null ||
                _locationStatus != 'Getting your location...')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemFill,
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_nearestDistrict != null)
                            Text(
                              'Nearest District: $_nearestDistrict',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          Text(
                            _locationStatus,
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _getCurrentLocation,
                      child: const Icon(CupertinoIcons.refresh),
                    ),
                  ],
                ),
              ),
            // Districts list
            Expanded(
              child: ListView.separated(
                itemCount: _filteredDistricts.length,
                separatorBuilder:
                    (context, index) => Container(
                      height: 0.5,
                      color: CupertinoColors.separator,
                      margin: EdgeInsets.zero,
                    ),
                itemBuilder: (context, index) {
                  final district = _filteredDistricts[index];
                  final isNearest = district.district == _nearestDistrict;
                  return GestureDetector(
                    onTap: () => _showDistrictInfo(context, district),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isNearest
                                ? CupertinoColors.systemYellow.withOpacity(0.1)
                                : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isNearest)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                CupertinoIcons.location_solid,
                                color: CupertinoColors.systemYellow,
                                size: 16,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              district.district,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    isNearest
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                          _recyclingPreviewIcons(district),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recyclingPreviewIcons(DistrictRecycling district) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (district.glass)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.wineBottle,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
        if (district.metal)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.cube,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
        if (district.paperCardboard)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.boxOpen,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
        if (district.plasticPETE)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.bottleWater,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
        if (district.smallElectrics)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.plug,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
        if (district.gardenWaste)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FaIcon(
              FontAwesomeIcons.leaf,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
      ],
    );
  }

  void _showDistrictInfo(BuildContext context, DistrictRecycling district) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            district.district,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          message: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _recyclingRow('Glass', district.glass),
              _recyclingRow('Metal', district.metal),
              _recyclingRow('Paper & Cardboard', district.paperCardboard),
              _recyclingRow('Plastic PETE', district.plasticPETE),
              _recyclingRow('Plastic PVC', district.plasticPVC),
              _recyclingRow('Plastic HDPE', district.plasticHDPE),
              _recyclingRow('Plastic PP', district.plasticPP),
              _recyclingRow('Small Electrics', district.smallElectrics),
              _recyclingRow('Garden Waste', district.gardenWaste),
            ],
          ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        );
      },
    );
  }

  Widget _recyclingRow(String label, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            available
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.xmark_circle,
            color:
                available
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
            size: 26,
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<MaterialInfo> _filteredMaterials = _getAllMaterials();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = _getAllMaterials();
      } else {
        _filteredMaterials =
            _getAllMaterials()
                .where((m) => m.name.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showAndFocusSearchBar() {
    setState(() {
      _showSearch = true;
    });
    Future.delayed(Duration.zero, () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle:
            _showSearch
                ? CupertinoSearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  placeholder: 'Search for a material...',
                )
                : const Text('Materials'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _showSearch ? CupertinoIcons.clear : CupertinoIcons.search,
          ),
          onPressed: () {
            if (_showSearch) {
              setState(() {
                _showSearch = false;
                _searchController.clear();
              });
            } else {
              _showAndFocusSearchBar();
            }
          },
        ),
      ),
      child: SafeArea(
        child: ListView.separated(
          itemCount: _filteredMaterials.length,
          separatorBuilder:
              (context, index) => Container(
                height: 0.5,
                color: CupertinoColors.separator,
                margin: EdgeInsets.zero,
              ),
          itemBuilder: (context, index) {
            final material = _filteredMaterials[index];
            return GestureDetector(
              onTap: () => _showMaterialInfo(context, material),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FaIcon(
                        material.icon,
                        color: CupertinoColors.activeBlue,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        material.name,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Text(
                      '${material.districtCount} districts',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMaterialInfo(BuildContext context, MaterialInfo material) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            material.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          message: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available in these districts:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...material.districts.map(
                (district) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(district, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        );
      },
    );
  }
}

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Camera Error'),
                content: Text('Failed to access camera: $e'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    if (_image == null) return;

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'recycling@centrala.cea.com',
      query:
          'subject=Recycling Query&body=Please analyze this item for recycling potential.',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text('Could not open email app'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Photo Query')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.contain),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.camera,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Take a photo of an item to query its recycling potential',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _takePhoto,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.camera, size: 20),
                      const SizedBox(width: 8),
                      Text(_image == null ? 'Take Photo' : 'Take New Photo'),
                    ],
                  ),
                ),
              ),
              if (_image != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _sendEmail,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.envelope, size: 20),
                        SizedBox(width: 8),
                        Text('Send to Recycling Team'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MaterialInfo {
  final String name;
  final IconData icon;
  final List<String> districts;
  final int districtCount;

  MaterialInfo({
    required this.name,
    required this.icon,
    required this.districts,
    required this.districtCount,
  });
}

List<MaterialInfo> _getAllMaterials() {
  final materials = <String, MaterialInfo>{};

  final materialDefinitions = {
    'Glass': FontAwesomeIcons.wineBottle,
    'Metal': FontAwesomeIcons.cube,
    'Paper & Cardboard': FontAwesomeIcons.boxOpen,
    'Plastic PETE': FontAwesomeIcons.bottleWater,
    'Plastic PVC': FontAwesomeIcons.bottleWater,
    'Plastic HDPE': FontAwesomeIcons.bottleWater,
    'Plastic PP': FontAwesomeIcons.bottleWater,
    'Small Electrics': FontAwesomeIcons.plug,
    'Garden Waste': FontAwesomeIcons.leaf,
  };

  for (final district in recyclingData) {
    final availableMaterials = <String>[];

    if (district.glass) availableMaterials.add('Glass');
    if (district.metal) availableMaterials.add('Metal');
    if (district.paperCardboard) availableMaterials.add('Paper & Cardboard');
    if (district.plasticPETE) availableMaterials.add('Plastic PETE');
    if (district.plasticPVC) availableMaterials.add('Plastic PVC');
    if (district.plasticHDPE) availableMaterials.add('Plastic HDPE');
    if (district.plasticPP) availableMaterials.add('Plastic PP');
    if (district.smallElectrics) availableMaterials.add('Small Electrics');
    if (district.gardenWaste) availableMaterials.add('Garden Waste');

    for (final material in availableMaterials) {
      if (materials.containsKey(material)) {
        materials[material]!.districts.add(district.district);
      } else {
        materials[material] = MaterialInfo(
          name: material,
          icon: materialDefinitions[material] ?? FontAwesomeIcons.recycle,
          districts: [district.district],
          districtCount: 1,
        );
      }
    }
  }

  for (final material in materials.values) {
    materials[material.name] = MaterialInfo(
      name: material.name,
      icon: material.icon,
      districts: material.districts,
      districtCount: material.districts.length,
    );
  }

  return materials.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}
