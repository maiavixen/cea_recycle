import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
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

class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
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
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.mobileScreen, size: 20),
            label: 'Sensors',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const DistrictListScreen();
          case 1:
            return const MaterialListScreen();
          case 2:
            return const PhotoCaptureScreen();
          case 3:
            return const SensorScreen();
          default:
            return const DistrictListScreen();
        }
      },
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
            return GestureDetector(
              onTap: () => _showDistrictInfo(context, district),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        district.district,
                        style: const TextStyle(fontSize: 18),
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

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  double _accelerometerX = 0.0;
  double _accelerometerY = 0.0;
  double _accelerometerZ = 0.0;
  double _gyroscopeX = 0.0;
  double _gyroscopeY = 0.0;
  double _gyroscopeZ = 0.0;
  Position? _position;
  String _locationStatus = 'Unknown';

  int _tapCount = 0;
  int _longPressCount = 0;
  int _swipeCount = 0;
  String _lastGesture = 'None';
  Offset? _panStart;
  double _totalPanDistance = 0.0;
  double _shakeThreshold = 12.0;
  bool _isShaking = false;

  // Stream subscriptions
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSensors();
    _getCurrentLocation();
  }

  void _initializeSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;

        double magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        if (magnitude > _shakeThreshold && !_isShaking) {
          _isShaking = true;
          _lastGesture = 'Shake detected!';
          // Reset shake detection after 1 second
          Timer(const Duration(seconds: 1), () {
            _isShaking = false;
          });
        }
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeX = event.x;
        _gyroscopeY = event.y;
        _gyroscopeZ = event.z;
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
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
            _locationStatus = 'Permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Permission denied permanently';
        });
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _locationStatus = 'Getting location...';
        });

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        setState(() {
          _position = position;
          _locationStatus = 'Location acquired';
        });
      } else {
        setState(() {
          _locationStatus = 'Permission denied';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: ${e.toString()}';
      });
    }
  }

  void _handleTap() {
    setState(() {
      _tapCount++;
      _lastGesture = 'Tap';
    });
  }

  void _handleLongPress() {
    setState(() {
      _longPressCount++;
      _lastGesture = 'Long Press';
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _panStart = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_panStart != null) {
      double distance = (details.globalPosition - _panStart!).distance;
      setState(() {
        _totalPanDistance += distance;
      });
    }
    _panStart = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _swipeCount++;
      _lastGesture = 'Swipe/Pan';
    });
  }

  void _showLocationHelp() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Location Help'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current status: '),
                Text(
                  _locationStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Troubleshooting:\n'
                  '• Enable location services in Settings\n'
                  '• Grant location permission to this app\n'
                  '• Check if you\'re in an area with GPS signal\n'
                  '• Try refreshing location again',
                ),
              ],
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

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sensor & Gesture Demo'),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard('Device Sensors', [
                  _buildSensorRow('Accelerometer X', _accelerometerX, 'm/s²'),
                  _buildSensorRow('Accelerometer Y', _accelerometerY, 'm/s²'),
                  _buildSensorRow('Accelerometer Z', _accelerometerZ, 'm/s²'),
                  const SizedBox(height: 8),
                  _buildSensorRow('Gyroscope X', _gyroscopeX, 'rad/s'),
                  _buildSensorRow('Gyroscope Y', _gyroscopeY, 'rad/s'),
                  _buildSensorRow('Gyroscope Z', _gyroscopeZ, 'rad/s'),
                ]),

                const SizedBox(height: 16),

                _buildSectionCard('Location Services', [
                  _buildInfoRow('Status', _locationStatus),
                  if (_position != null) ...[
                    _buildInfoRow(
                      'Latitude',
                      _position!.latitude.toStringAsFixed(6),
                    ),
                    _buildInfoRow(
                      'Longitude',
                      _position!.longitude.toStringAsFixed(6),
                    ),
                    _buildInfoRow(
                      'Altitude',
                      '${_position!.altitude.toStringAsFixed(2)} m',
                    ),
                    _buildInfoRow(
                      'Accuracy',
                      '${_position!.accuracy.toStringAsFixed(2)} m',
                    ),
                    _buildInfoRow(
                      'Speed',
                      '${_position!.speed.toStringAsFixed(2)} m/s',
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _getCurrentLocation,
                      child: const Text('Refresh Location'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: _showLocationHelp,
                      child: const Text('Location Help'),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                _buildSectionCard('Gesture Recognition', [
                  const Text(
                    'Try different gestures on this screen:',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Last Gesture', _lastGesture),
                  _buildInfoRow('Tap Count', _tapCount.toString()),
                  _buildInfoRow('Long Press Count', _longPressCount.toString()),
                  _buildInfoRow('Swipe Count', _swipeCount.toString()),
                  _buildInfoRow(
                    'Total Pan Distance',
                    '${_totalPanDistance.toStringAsFixed(2)} px',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _tapCount = 0;
                          _longPressCount = 0;
                          _swipeCount = 0;
                          _totalPanDistance = 0.0;
                          _lastGesture = 'None';
                        });
                      },
                      child: const Text('Reset Gesture Counters'),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // Instructions Section
                _buildSectionCard('Instructions', [
                  const Text(
                    '• Tap anywhere to increase tap count\n'
                    '• Long press to increase long press count\n'
                    '• Swipe or drag to increase swipe count\n'
                    '• Shake the device to trigger shake detection\n'
                    '• Move the device to see accelerometer changes\n'
                    '• Rotate the device to see gyroscope changes',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${value.toStringAsFixed(3)} $unit',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
