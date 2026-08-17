import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WeatherScreen(),
  ));
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherScreenState createState() => _WeatherScreenState();

}

class _WeatherScreenState extends State<WeatherScreen> {

  Color startColor = Colors.blue;
  Color endColor = Colors.lightBlueAccent;

  TextEditingController cityController = TextEditingController();

  String temperature = "";
  String weather = "";
  String errorMessage = "";
  IconData weatherIcon = Icons.wb_sunny;

  int humidity = 0;
  double windSpeed = 0;
  String sunrise = "";
  String sunset = "";
  int aqi = 0;
  String aqiText = "";

  bool isLoading = false;

  List forecastData = [];

  String apiKey = "REMOVED";


  // 🌤 GET CURRENT WEATHER
  Future getWeather() async {
    String city = cityController.text;
    print("Getting weather for city: $city");

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    var url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric"
    );

    var response = await http.get(url);
    var data = jsonDecode(response.body);

    if (response.statusCode != 200) {
  setState(() {
    errorMessage = "City not found ❌";
    temperature = "";
    weather = "";
    isLoading = false;
  });
  return;
 }

    setState(() {
      temperature = data['main']['temp'].toString();
      weather = data['weather'][0]['description'];

      print("Weather data received: $weather");
      
      humidity = data['main']['humidity'];
      windSpeed = data['wind']['speed'];

      int sunriseTime = data['sys']['sunrise'];
      int sunsetTime = data['sys']['sunset'];

      sunrise = DateTime.fromMillisecondsSinceEpoch(sunriseTime * 1000)
          .toLocal()
          .toString()
          .split(" ")[1]
          .substring(0,5);

      sunset = DateTime.fromMillisecondsSinceEpoch(sunsetTime * 1000)
          .toLocal()
          .toString()
          .split(" ")[1]
          .substring(0,5); 

      int currentTime = DateTime.now().hour;
      print("Time: $currentTime");

      bool isNight = DateTime.now().isAfter(
         DateTime.fromMillisecondsSinceEpoch(sunsetTime * 1000)
      );

      String w = weather.toLowerCase();

       if (getWeatherAlert() != "") {
         startColor = Colors.red.shade700;
         endColor = Colors.black;
       }
       else if (weather.contains("clear")) {
         startColor = Colors.orange;
         endColor = Colors.blue;
       }
       else if (weather.contains("rain")) {
         startColor = Colors.grey;
         endColor = Colors.blueGrey;
       }

      if (isNight) {
        startColor = Colors.black;
        endColor = Colors.blueGrey;
      }
      else if (w.contains("clear") || w.contains("sun")) {
        startColor = Colors.orange;
        endColor = Colors.yellow;
      }
      else if (w.contains("cloud")) {
        startColor = Colors.grey;
        endColor = Colors.blueGrey;
      }
      else if (w.contains("rain") || w.contains("thunder") || w.contains("thunderstorm")) {
        startColor = Colors.indigo;
        endColor = Colors.blue;
      }

      else if (w.contains("haze") || w.contains("fog") || w.contains("mist")) {
         startColor = Colors.blueGrey;
         endColor = Colors.grey;
      }

      else if (w.contains("snow") || w.contains("light snow") || w.contains("heavy snow")) {
         startColor = Colors.lightBlueAccent;
         endColor = Colors.white;
     }

      else {
         startColor = Colors.blue;
         endColor = Colors.lightBlueAccent;
    }


    print("Theme: $startColor -> $endColor");


      isLoading = false;


    });
    double lat = data['coord']['lat'];
    double lon = data['coord']['lon'];

    getAQI(lat, lon);
    await getForecast(); // 👈 call forecast
  }

  // 📅 GET FORECAST
  Future getForecast() async {
    String city = cityController.text;

    var url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric"
    );

    var response = await http.get(url);
    var data = jsonDecode(response.body);

    // ignore: unrelated_type_equality_checks
    if (response.statusCode != 200) return;

    List dailyData = [];

    for (int i = 0; i < data['list'].length; i += 8) {
      dailyData.add(data['list'][i]);
    }
    

    setState(() {
      forecastData = dailyData;
    });
  }

  Widget getWeatherAnimation() {
    String w = weather.toLowerCase();

    String animationPath = "assets/animations/sun.json";

    if (w.contains("clear")) {
      animationPath = "assets/animations/sun.json";
    } 
    else if (w.contains("cloud")) {
      animationPath = "assets/animations/cloud.json";
    } 
    else if (w.contains("rain") || w.contains("thunder")) {
      animationPath = "assets/animations/rain.json";
    } 
    else if (w.contains("haze") || w.contains("mist") || w.contains("fog") || w.contains("smoke")) {
      animationPath = "assets/animations/fog.json";
    }

  // ✅ PRINT MUST BE INSIDE FUNCTION
    print("Using animation: $animationPath");

  // ✅ CORRECT RETURN
    return Lottie.asset(
      animationPath,
      repeat: true,   // ✅ correct syntax
      fit: BoxFit.contain,
    );
  }

  Color getBackgroundColor() {
  String w = weather.toLowerCase();

  if (w.contains("clear")) return Colors.orange;
  if (w.contains("cloud")) return Colors.grey;
  if (w.contains("rain") || w.contains("thunderstorm")) return Colors.blueGrey;
  if (w.contains("fog") || w.contains("mist") || w.contains("smoke") || w.contains("haze")) return Colors.blueGrey.shade200;

  return Colors.blue;
}

String getWeatherSuggestion() {
  String w = weather.toLowerCase();
  double temp = double.tryParse(temperature) ?? 0;

  if (w.contains("rain")) {
    return "Carry an umbrella ☔";
  } 
  else if (temp > 35) {
    return "Drink water 💧 and wear light clothes ☀️";
  } 
  else if (temp < 15) {
    return "Wear a jacket 🧥";
  } 
  else if (w.contains("cloud")) {
    return "Nice weather for a walk 🚶";
  } 
  else {
    return "Enjoy your day 😊";
  }
}

String getWeatherAlert() {
  String w = weather.toLowerCase();
  double temp = double.tryParse(temperature) ?? 0;

  if (w.contains("thunderstorm")) {
    return "⚠️ Thunderstorm Alert! Stay indoors and avoid open areas.";
  } 
  else if (w.contains("heavy rain")) {
    return "⚠️ Heavy Rain Alert! Risk of flooding. Stay safe.";
  } 
  else if (w.contains("rain")) {
    return "🌧 Rain Alert! Carry umbrella.";
  } 
  else if (temp > 40) {
    return "🔥 Heatwave Alert! Avoid going out in afternoon.";
  } 
  else if (temp < 5) {
    return "❄️ Cold Wave Alert! Stay warm.";
  } 
  else if (w.contains("fog") || w.contains("mist") || w.contains("smoke")) {
    return "⚠️ Low Visibility Alert! Drive carefully.";
  } 
  else {
    return ""; // no alert
  }
}

  Future getAQI(double lat, double lon) async {
    var url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey"
    );

    var response = await http.get(url);

    if (kDebugMode) {
      print(response.body);
    }

    var data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        aqi = data['list'][0]['main']['aqi'];

        if (aqi == 1) {
          aqiText = "Good 😊";
        } else if (aqi == 2) 
          // ignore: curly_braces_in_flow_control_structures
          aqiText = "Fair 😐";
        else if (aqi == 3) 
          // ignore: curly_braces_in_flow_control_structures
          aqiText = "Moderate 😕";
        else if (aqi == 4) 
          // ignore: curly_braces_in_flow_control_structures
          aqiText = "Poor 😷";
        else if (aqi == 5) 
          // ignore: curly_braces_in_flow_control_structures
          aqiText = "Very Poor 😰";
      });
    }
  }

  // 📍 AUTO LOCATION
  Future getCurrentLocationWeather() async {
    print("Getting current location weather...");
    try {
      await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = placemarks.isNotEmpty && placemarks[0].locality != null
          ? placemarks[0].locality!
          : "Mumbai";

      print("Detected city: $city");
      cityController.text = city;

      await getWeather(); // IMPORTANT
      await getAQI(position.latitude, position.longitude);

    } catch (e) {
      print("Location error: $e");

      // fallback city
      cityController.text = "Mumbai";
      await getWeather();
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocationWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Colors.blueAccent,
      Colors.deepPurpleAccent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
 ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              SizedBox(height: 40),

              Text(
                "Weather App",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              TextField(
                controller: cityController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter City",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {
                  getWeather();
                },
                child: Text("Get Weather"),
              ),

              SizedBox(height: 20),

              if (errorMessage != "")
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),

              if (isLoading)
                CircularProgressIndicator(color: Colors.white),

              SizedBox(height: 20),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                   child: Container(
                     height: 200,
                     width: 200,
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.15),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(
                         color: Colors.white.withOpacity(0.3),
                         width: 1,                       
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: getWeatherAnimation(),
                     ),
                   ),
                 ),
               ),
              ),
              SizedBox(height: 10),

              Text(
                temperature == "" ? "" : "$temperature°C",
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              
              SizedBox(height: 10),

              Text(
                weather,
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 10),

             Text(
               getWeatherSuggestion(),
               textAlign: TextAlign.center,
               style: TextStyle(
                 fontSize: 18,
                 color: Colors.white70,
                 fontStyle: FontStyle.italic,
               ),
             ),

              // 🌦 FORECAST
              SizedBox(height: 20),

              if (getWeatherAlert() != "")
                Container(
                 width: double.infinity,
                 padding: EdgeInsets.all(12),
                 margin: EdgeInsets.only(bottom: 15),
                 decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    getWeatherAlert(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                 ),
               ),

            Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    Column(
                      children: [
                        Icon(Icons.water_drop, color: Colors.white),
                        Text("Humidity", style: TextStyle(color: Colors.white)),
                        Text("$humidity%", style: TextStyle(color: Colors.white)),
                      ],
                    ),

                    Column(
                      children: [
                        Icon(Icons.air, color: Colors.white),
                        Text("Wind", style: TextStyle(color: Colors.white)),
                        Text("$windSpeed m/s", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    Column(
                      children: [
                        Icon(Icons.wb_sunny, color: Colors.yellow),
                        Text("Sunrise", style: TextStyle(color: Colors.white)),
                        Text(sunrise, style: TextStyle(color: Colors.white)),
                      ],
                    ),

                    Column(
                      children: [
                        Icon(Icons.nightlight_round, color: Colors.white),
                        Text("Sunset", style: TextStyle(color: Colors.white)),
                        Text(sunset, style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Text(
                  "AQI: $aqi ($aqiText)",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),
                
              Text(
                "5-Day Forecast",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: forecastData.length > 5 ? 5 : forecastData.length,
                  itemBuilder: (context, index) {

                    var item = forecastData[index];

                    DateTime date = DateTime.parse(item['dt_txt']);
                    String day = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][date.weekday % 7];

                    var temp = item['main']['temp'];
                    var condition = item['weather'][0]['main'];

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Text(
                            day,
                            style: TextStyle(color: Colors.white),
                         ),

                          Text(
                            "${temp.toString()}°C",
                            style: TextStyle(color: Colors.white),
                          ),

                          SizedBox(height: 5),

                          Text(
                            condition,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    ),
    );
  }
}