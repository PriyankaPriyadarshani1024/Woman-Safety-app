import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'task.dart'; // Import the task.dart file to fetch contacts
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background/flutter_background.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FlutterSoundRecorder _audioRecorder;
  late FlutterSoundPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _predictionResult = 'Loading model...';
  String _recordedFilePath = '';
  late Interpreter _interpreter;
  List<String> _predictions = [];
  int _recordingTime = 0;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration(minutes: 3); // 3 minutes
  bool _userStopped = false; // Track if user stopped recording


  Future<void> _startBackgroundTasks() async {
    bool success = await FlutterBackground.initialize();
    if (success) {
      // Allow your app to run in the background
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> _startRecordingInBackground() async {
    await _startBackgroundTasks();
   _startRecording(); // Start the recording in the foreground or background
 }

  Future<void> _stopRecordingInBackground() async {
    await FlutterBackground.disableBackgroundExecution();
    _stopRecording(); // Stop recording when the task is finished
  }


  // Define emotion labels corresponding to model output classes
  final List<String> _emotionLabels = [
    'Anger', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise'
  ];

  List<Contact> _savedContacts = [];
  String _smsStatus = '';
  bool _autoSendEnabled = false;
  Timer? _smsTimer;
  Timer? _countdownTimer;
  int _countdown = 10;
  bool _smsCancelled = false; // Flag to track SMS cancellation

  final ContactService _contactService = ContactService(
    client: Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('66eee5c400107d2ac9c7'),
  );


  Timer? _autoRecordTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _loadModel();
    _fetchContacts();
    _startRecordingInBackground();
    _timer?.cancel();
    _startBackgroundRecordingCycle(); // Fetch saved contacts on init
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    if (_audioPlayer.isOpen()) {
      _audioPlayer.closePlayer(); // Close the player when no longer needed
    }
    _smsTimer?.cancel();
    _countdownTimer?.cancel();
    _autoRecordTimer?.cancel();
    _interpreter.close();
    _recordingTimer?.cancel();
    super.dispose();
  }
  Future<void> _startBackgroundRecordingCycle() async {
    // Call the _startRecording every 3 minutes
    _autoRecordTimer = Timer.periodic(Duration(minutes: 3), (timer) async {
      await _startRecording();
      await Future.delayed(Duration(minutes: 2)); // Record for 2 minutes
      await _stopRecording();
    });
  }

  Future<void> _processAudioAndSendSms() async {
    // Perform background tasks like processing audio and sending SMS
    try {
      var emotion = await _processAudio(_recordedFilePath);
    } catch (e) {
      print("Error in background task: $e");
    }
  }

  // Start recording automatically every 3 minutes
  Future<void> _startRecordingAutomatically() async {
    if (_isRecording) return;
    await _startRecording();

    _autoRecordTimer = Timer.periodic(Duration(minutes: 3), (timer) {
      if (_isRecording) {
        _stopRecording();
      } else {
        _startRecording();
      }
    });
  }

  // Stop the automatic recording loop
  Future<void> _stopRecordingAutomatically() async {
    _autoRecordTimer?.cancel(); // Stop the periodic timer
    if (_isRecording) {
      await _stopRecording(); // Stop the recording if it's still ongoing
    }
  }

  // Get the current location (latitude and longitude)
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check if location permission is granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  String _generateLocationUrl(Position position) {
    return 'https://www.google.com/maps?q=${position.latitude},${position
        .longitude}';
  }

  // Load the emotion recognition model using tflite_flutter
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/res_model1.tflite');
      setState(() {
        _predictionResult = 'Model loaded successfully!';
      });
    } catch (e) {
      setState(() {
        _predictionResult = 'Failed to load model: $e';
      });
    }
  }

  // Fetch contacts from the Appwrite database
  Future<void> _fetchContacts() async {
    try {
      await _contactService.fetchContacts(
        databaseId: '66eef6c00023912361eb', // Your Appwrite database ID
        collectionId: '66f44198002e59611338', // Your Appwrite collection ID
        setContacts: (contacts) {
          setState(() {
            _savedContacts = contacts;
          });
        },
      );
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }




  // Start recording voice
  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      await _audioRecorder.openRecorder();
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      _recordedFilePath = '${appDocDirectory.path}/audio_recording.wav';
      await _audioRecorder.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.pcm16WAV,
      );
      // Set up a timer to stop the recording after 3 minutes
     // _recordingTimer = Timer(Duration(minutes: 3), _stopRecording);

      setState(() {
        _isRecording = true;
        _recordingTime = 0;
        _predictions.clear();
        _predictionResult = 'Recording started...';
      });

      // Timer for sending predictions after every 3 minutes
      //_timer = Timer.periodic(Duration(seconds: 180), (timer) {
       // _predictEmotion();
      //});
    } catch (e) {
      setState(() {
        _predictionResult = 'Error while starting recording: $e';
      });
    }
  }

  // Stop recording and process the audio
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _predictionResult = 'Recording stopped. Processing...';
      });
      _processAudio(_recordedFilePath);
      // Cancel the recording timer if the user stops manually
      //_recordingTimer?.cancel();
      _predictEmotion();
      File file = File(_recordedFilePath);
      if (await file.exists()) {
        print('File recorded successfully at: ${file.path}');
      } else {
        print('File does not exist!');
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Error while stopping recording: $e';
      });
    }
  }
  // Method to handle the emotion prediction logic
  Future<void> _predictEmotion() async {
    try {
      if (!mounted) return;  // Check if the widget is still mounted

      setState(() {
        _predictionResult = 'Predicting Emotion...';
      });

      // Process the recorded audio and make the prediction
      await _processAudio(_recordedFilePath);
    } catch (e) {
      if (!mounted) return;  // Check again if the widget is still mounted

      setState(() {
        _predictionResult = 'Error during emotion prediction: $e';
      });

    }
  }


  // Process the recorded audio and get emotion prediction
  Future<void> _processAudio(String audioFilePath) async {
    try {
      var audioFeatures = await _extractFeatures(audioFilePath);
      var input = audioFeatures.reshape([1, 2376, 1]);
      var output = List<List<double>>.filled(1, List.filled(7, 0.0));

      _interpreter.run(input, output);

      double maxValue = -double.infinity;
      int predictedIndex = -1;

      for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          predictedIndex = i;
        }
      }

      String predictedEmotion = _emotionLabels[predictedIndex];
      setState(() {
        print('Model output: ${output[0]}');

        _predictionResult = 'Predicted Emotion: $predictedEmotion';
      });

      // Start the countdown before sending SMS
      _startSmsCountdown(predictedEmotion);
    } catch (e) {
      setState(() {
        _predictionResult = 'Error processing audio: $e';
      });
    }
  }

  // Extract audio features (placeholder for actual feature extraction)
  Future<List<List<double>>> _extractFeatures(String audioFilePath) async {
    return List.generate(
        2376, (i) => [0.0]); // Placeholder for actual feature extraction
  }

  // Start SMS countdown
  void _startSmsCountdown(String emotion) {
    _countdown = 10;
    _smsCancelled = false; // Reset the SMS cancellation flag
    _countdownTimer?.cancel();

    // Update countdown every second
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _smsStatus = 'Sending in $_countdown seconds...';
        });
        _countdown--;
      } else {
        _countdownTimer?.cancel();
        if (!_smsCancelled) {
          _sendSms(emotion);
        }
      }
    });
  }

  // Send SMS using Twilio API
  Future<void> _sendSms(String emotion) async {
    try {
      Position position = await _getCurrentLocation();

      // Generate Google Maps URL with current location
      String locationUrl = _generateLocationUrl(position);

      // Create the SMS message
      String message = "I am in danger! Emotion detected: $emotion. My location: $locationUrl";

      var accountSid = 'AC75cf89a6584cdf677f6060f6099c553b';
      var authToken = '1f367b233ff59bbc1ae2b34e5712f087';
      var fromPhoneNumber = '+13345184805';

      final twilioFlutter = TwilioFlutter(
        accountSid: accountSid,
        authToken: authToken,
        twilioNumber: fromPhoneNumber,
      );

      for (Contact contact in _savedContacts) {
        var response = await twilioFlutter.sendSMS(
          toNumber: contact.phone,
          messageBody: message,
        );
        setState(() {
          _smsStatus = 'SMS sent to ${contact.phone} with SID: ${response.sid}';
        });
      }
    } catch (e) {
      setState(() {
        _smsStatus = 'Error sending SMS: $e';
      });
    }
  }
  void _stopSmsCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _smsCancelled = true;
      _smsStatus = 'SMS sending cancelled';
    });
  }

  void _stopSmsTimer() {
    _smsTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _autoSendEnabled = false;
      _smsStatus = 'SMS sending stopped';
    });
  }
  // Stop SMS sending
  void _stopSms() {
    setState(() {
      _smsCancelled = true; // Set SMS cancelled flag to true
      _countdownTimer?.cancel(); // Cancel the countdown timer
    });
  }

  // Play the recorded audio
  Future<void> _playRecording() async {
    try {
      if (!_audioPlayer.isOpen()) {
        await _audioPlayer.openPlayer();
      }
      if (_recordedFilePath.isNotEmpty) {
        print('Playing recorded file from: $_recordedFilePath');
        await _audioPlayer.startPlayer(
          fromURI: _recordedFilePath,
          codec: Codec.pcm16WAV,
      );
      setState(() {
        _isPlaying = true;
      });
      } else {
        print('No recorded file found to play.');
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Error while playing audio: $e';
      });
    }
  }

  // Stop playing the recorded audio
  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _predictionResult = 'Error while stopping audio: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('I am listening you',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prediction result text with a bold style

              ElevatedButton(
                onPressed: () => _sendSms(_predictionResult), // Send SMS based on detected emotion
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red background color
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Larger padding for a bigger button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Round the corners for a more circular button
                  ),
                ),
                child: Text(
                  'Danger',
                  style: TextStyle(
                    fontSize: 18, // Larger text size
                    color: Colors.white,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
    ),

              Text(
                _predictionResult,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Countdown Timer
              //Text(
               // 'Time remaining: $_countdown seconds',
               // style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
             // ),
              //SizedBox(height: 20),

              // Start or Stop Recording Button
              ElevatedButton(
                onPressed: _isRecording ? null : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _isRecording ? 'Recording in Progress...' : 'Start Recording',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

              // Stop Recording Button (Only visible when recording)
              if (_isRecording)
                ElevatedButton(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Stop Recording',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              SizedBox(height: 20),

              // Play and Stop Recording Buttons
              if (!_isRecording)
                ElevatedButton(
                  onPressed: _isPlaying ? _stopPlaying : _playRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.orangeAccent : Colors
                        .greenAccent,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _isPlaying ? 'Stop Playing' : 'Play Recording',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              SizedBox(height: 20),

              // SMS Status Display
              if (_smsStatus.isNotEmpty)
                Text(
                  _smsStatus,
                  style: TextStyle(fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),

             // if (_smsStatus.isNotEmpty)
               // Column(
               //   children: [
               //     Text(_smsStatus),
               //     SizedBox(height: 10),
               //     ElevatedButton(
               //       onPressed: _smsCancelled ? null : _stopSmsCountdown,
               //       child: Text('Cancel SMS'),
               //     ),
              //    ],
              //  ),
              if (_autoSendEnabled)
                ElevatedButton(
                  onPressed: _stopSmsTimer,
                  child: Text('Stop SMS Sending'),
                ),


              // Stop SMS Button
              ElevatedButton(
                onPressed: _stopSms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Stop SMS',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}



  extension on TwilioResponse {
  get sid => null;
}