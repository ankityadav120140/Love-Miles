import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String myID = '';
  GeoPoint myLoc = GeoPoint(0, 0);
  GeoPoint herLoc = GeoPoint(37.7749, -122.4194);
  String msg = '';
  double dis = 0;
  DateTime timePoint = DateTime(2020, 9, 11, 0, 30, 0); // Example time point
  Timer? timer;
  String formattedDuration = '';

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        Duration duration = DateTime.now().difference(timePoint);
        formattedDuration = formatDuration(duration);
      });
    });
  }

  Future<void> myDevice() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final PermissionStatus status = await Permission.location.request();
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      GeoPoint currentLocation =
          GeoPoint(position.latitude, position.longitude);

      if (androidInfo.id != "TP1A.220905.001") {
        uploadHerLoc(currentLocation);
      } else {
        uploadHisLoc(currentLocation);
      }

      print('Running on ${androidInfo.id}');
    } catch (e) {
      // Handle error
      print('Error: $e');
    }
  }

  Future<void> uploadHerLoc(GeoPoint location) async {
    try {
      CollectionReference myCollection =
          FirebaseFirestore.instance.collection('myCollection');
      DocumentReference dewkitDoc = myCollection.doc('dewkit');

      // Update the 'herLoc' field in the 'dewkit' document
      await dewkitDoc.update({
        'herLoc': location,
      });

      print('Her location uploaded successfully');
    } catch (e) {
      // Handle error
      print('Error uploading her location: $e');
    }
  }

  Future<void> uploadHisLoc(GeoPoint location) async {
    try {
      CollectionReference myCollection =
          FirebaseFirestore.instance.collection('myCollection');
      DocumentReference dewkitDoc = myCollection.doc('dewkit');

      // Update the 'hisLoc' field in the 'dewkit' document
      await dewkitDoc.update({
        'hisLoc': location,
      });

      print('His location uploaded successfully');
    } catch (e) {
      // Handle error
      print('Error uploading his location: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('myCollection')
          .doc('dewkit')
          .get();

      if (snapshot.exists) {
        setState(() {
          myLoc = snapshot.get('hisLoc');
          herLoc = snapshot.get('herLoc');
          msg = snapshot.get('msg');
        });
      }
    } catch (e) {
      // Handle error
      print('Error: $e');
    }
    setState(() {
      dis = calculateDistance(myLoc, herLoc);
    });
  }

  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    // Radius of the Earth in kilometers
    const double earthRadius = 6371;

    // Convert degrees to radians
    final double lat1 = degreesToRadians(point1.latitude);
    final double lon1 = degreesToRadians(point1.longitude);
    final double lat2 = degreesToRadians(point2.latitude);
    final double lon2 = degreesToRadians(point2.longitude);

    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate the distance
    final double distance = earthRadius * c;

    return distance;
  }

  double degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  String formatDuration(Duration duration) {
    int years = duration.inDays ~/ 365;
    int remainingDays = duration.inDays % 365;

    int months = remainingDays ~/ 30;
    int days = remainingDays % 30;

    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return '$years years, $months months, $days days, $hours hours, $minutes minutes, $seconds seconds';
  }

  @override
  void initState() {
    super.initState();
    myDevice();
    fetchData();
    startTimer();
    // Calculate the duration and format it
    Duration duration = DateTime.now().difference(timePoint);
    formattedDuration = formatDuration(duration);

    setState(() {
      formattedDuration = formattedDuration;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Love Miles"),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/1.jpeg',
                        fit: BoxFit.cover,
                        // width: double.infinity,
                        // height: double.infinity,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: MediaQuery.of(context).size.width * 0.27,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        // width: double.infinity,
                        // height: double.infinity,
                        color: Colors.white.withOpacity(0.5),
                        child: Text(
                          "${dis.toStringAsFixed(2)} KM apart",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/2.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      color: Colors.white.withOpacity(0.5),
                      child: Text(
                        '$formattedDuration \n of togetherness',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
