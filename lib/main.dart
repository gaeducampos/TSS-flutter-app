import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Lecto UFG '),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum TtsState { playing, stopped, paused, continued }

class _MyHomePageState extends State<MyHomePage> {
  String? _newVoiceText;
  String _pdfText = "";
  int _counterLoad = 15;

  List<dynamic> list = [];
  int longDivision = 0;
  int remainder = 0;
  String TextRemainder = "";

  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  var _counter = 0;

  FlutterTts flutterTts = FlutterTts();
  Timer? timer;
  var _controller = TextEditingController();

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  Future _speak() async {
    String? language = "es-ES";
    flutterTts.setLanguage(language);

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_counterLoad > 0) {
          _counterLoad--;
        } else {
          timer.cancel();
          _counterLoad = 15;
        }
      });
    });
  }

  void _decrement() {
    setState(() {
      _counter--;
      if (_counter == 0) {
        _counter = 0;
      }
    });
  }

  List<dynamic> splitArray(String srt, int lenght, int remainder) {
    var numChunks = (srt.length / lenght).ceil();

    var chunks = [];

    // print(numChunks);
    var isExact = remainder == 0;
    var maxValue = isExact ? numChunks : numChunks - 1;
    for (var i = 0, o = 0; i < maxValue; i++, o += lenght) {
      // print(i);
      chunks.add(srt.substring(o, o + lenght).toString());
    }

    if (!isExact) {
      chunks.add(
          srt.substring(srt.length - remainder, srt.length - 1).toString());
    }

    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    MaterialApp(
      debugShowCheckedModeBanner: false,
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _addImage(),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    PlatformFile file = result.files.first;
                    String? path = file.path;

                    PdfDocument document = PdfDocument(
                        inputBytes: File(path.toString()).readAsBytesSync());

                    String text = PdfTextExtractor(document).extractText();
                    text.toString();
                    text.replaceAll("\n", " ");

                    _pdfText = text;
                    print(_pdfText.length);
                    remainder = _pdfText.length % 1000;

                    if (_pdfText.length > 1000) {
                      list = splitArray(_pdfText, 1000, remainder);
                      _counter = list.length;
                    }
                  }

                  startTimer();
                },
                child: Text("Elegir Archivo")),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "Espera para copiar y pegar",
              style: TextStyle(fontSize: 20),
            ),
            _inputSection(),
            SizedBox(
              height: 20,
            ),
            bottomBar(),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  _decrement();
                  if (_pdfText.length <= 1000) {
                    Clipboard.setData(ClipboardData(text: _pdfText));
                  } else {
                    Clipboard.setData(ClipboardData(text: list[0]));
                    list.removeAt(0);
                    if (list.length == 0) {
                      AlertDialog(
                        title: Text("Ya no hay más texto en el libro"),
                      );
                    }
                  }
                },
                child: Text("Copiar Texto PDF")),
            SizedBox(
              height: 20,
            ),
            Text(
              "Restan de escuchar ${_counter} partes",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputSection() => Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: TextField(
        onChanged: (String value) {
          _onChange(value);
        },
        decoration: InputDecoration(
          hintText: "Pegue el texto del PDF",
          suffixIcon: IconButton(
            onPressed: _controller.clear,
            icon: Icon(Icons.clear),
          ),
        ),
        controller: _controller,
      ));

  bottomBar() => Container(
        margin: EdgeInsets.all(10.0),
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              onPressed: _speak,
              child: Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            ),
            FloatingActionButton(
              onPressed: _stop,
              backgroundColor: Colors.red,
              child: Icon(Icons.stop),
            ),
          ],
        ),
      );

  Widget _addImage() {
    return Container(
      height: 60,
      width: 60,
      child: Image.asset("assets/PDF_icon.png"),
    );
  }
}
