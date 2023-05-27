import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orthanc',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  SharedPreferences? _prefs;
  bool? _rememberMe;

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
  }

  void initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = _prefs?.getBool('rememberMe') ?? false;
      if (_rememberMe!) {
        usernameController.text = _prefs?.getString('username') ?? '';
        passwordController.text = _prefs?.getString('password') ?? '';
        urlController.text = _prefs?.getString('url') ?? '';
      }
    });
  }

  void _login(BuildContext context) {

     if (_rememberMe!) {
      _prefs?.setString('username', usernameController.text);
      _prefs?.setString('password', passwordController.text);
      _prefs?.setString('url', urlController.text);
    } else {
      _prefs?.remove('username');
      _prefs?.remove('password');
      _prefs?.remove('url');
    }

    // Navigate to another page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          url: urlController.text,
          username: usernameController.text,
          password: passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL',
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe ?? false,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value;
                    });
                  },
                ),
                Text('Remember me'),
              ],
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                _login(context);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String url;
  final String username;
  final String password;

  HomePage({required this.url, required this.username, required this.password});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _studies = [];

  @override
  void initState() {
    super.initState();
    _getStudies();
  }

  void _getStudies() async {
    print('${widget.url}');
    print('${widget.username}');
    print('${widget.password}');
    var response = await http.get(Uri.parse('${widget.url}studies?expand'));
    if (response.statusCode == 200) {
      setState(() {
        _studies = jsonDecode(response.body);
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orthanc'),
      ),
      body: ListView.builder(
        itemCount: _studies.length,
        itemBuilder: (context, index) {
          final study = _studies[index];
          //print('${_studies[index]['MainDicomTags']}');
          final studyDate =
              _studies[index]['PatientMainDicomTags']['PatientName'];
          final studyDescription =
              _studies[index]['MainDicomTags']['StudyDescription'];
          return ListTile(
            title: Text(studyDate ?? ''),
            subtitle: Text(studyDescription ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyDetails(study: study),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudyDetails extends StatefulWidget {
  final dynamic study;

  const StudyDetails({Key? key, required this.study}) : super(key: key);

  @override
  _StudyDetailsState createState() => _StudyDetailsState();
}

class _StudyDetailsState extends State<StudyDetails> {
  List<dynamic> _series = [];

  @override
  void initState() {
    super.initState();
    _getSeries();
  }

  void _getSeries() async {
    var response = await http.get(Uri.parse(
        'https://demo.orthanc-server.com/studies/${widget.study['ID']}/series?expand'));
    if (response.statusCode == 200) {
      setState(() {
        _series = jsonDecode(response.body);
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.study['PatientMainDicomTags']['PatientName']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Study Description: ${widget.study['MainDicomTags']['StudyDescription'] ?? ''}'),
            SizedBox(height: 8.0),
            Text(
                'Study Date: ${widget.study['MainDicomTags']['StudyDate'] ?? ''}'),
            SizedBox(height: 8.0),
            Text('Study ID: ${widget.study['ID']}'),
            SizedBox(height: 32.0),
            Text(
              'Series',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _series.length,
              itemBuilder: (context, index) {
                final series = _series[index];
                //print('${_series[index]['MainDicomTags']}');
                final seriesNumber =
                    _series[index]['MainDicomTags']['SeriesNumber'];
                final seriesDescription =
                    _series[index]['MainDicomTags']['SeriesDescription'];
                return ListTile(
                  title: Text(seriesNumber ?? ''),
                  subtitle: Text(seriesDescription ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeriesDetails(series: series),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SeriesDetails extends StatefulWidget {
  final dynamic series;

  const SeriesDetails({Key? key, required this.series}) : super(key: key);

  @override
  _SeriesDetailsState createState() => _SeriesDetailsState();
}

class _SeriesDetailsState extends State<SeriesDetails> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> _instances = widget.series['Instances'];
    final imageUrls = _instances
        .map((e) => 'https://demo.orthanc-server.com/instances/$e/file')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.series['MainDicomTags']['SeriesDescription']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Series Manufacturer: ${widget.series['MainDicomTags']['Manufacturer'] ?? ''}'),
            SizedBox(height: 8.0),
            Text(
                'Series Modality: ${widget.series['MainDicomTags']['Modality'] ?? ''}'),
            SizedBox(height: 8.0),
            Text(
                'Series Procedure Description: ${widget.series['MainDicomTags']['PerformedProcedureStepDescription'] ?? ''}'),
            SizedBox(height: 8.0),
            Text('Series ID: ${widget.series['ID']}'),
            SizedBox(height: 32.0),
            Text(
              'Instances',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: SingleChildScrollView(
                child: Scrollbar(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _instances.length,
                    itemBuilder: (context, index) {
                      //print('${_instances[index]}');
                      final instancesID = _instances[index];
                      return ListTile(
                        title: Text('$index: $instancesID'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
