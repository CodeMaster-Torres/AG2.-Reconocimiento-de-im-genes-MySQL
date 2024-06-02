import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ImageRecognition(),
    );
  }
}

class ImageRecognition extends StatefulWidget {
  const ImageRecognition({Key? key}) : super(key: key);

  @override
  State<ImageRecognition> createState() => _ImageRecognitionState();
}

class _ImageRecognitionState extends State<ImageRecognition> {
  final String baseUrl = "http://192.168.0.9:8080"; //

  List<Medicamentos> medicamentos = [];
  List? _outputs;
  File? _image;
  bool isLoading = false;

  Future<List<Medicamentos>> fetchData() async {
    final Uri url = Uri.parse("$baseUrl/ag2/fetch_medicamentos.php");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      medicamentos =
          data.map((m) => Medicamentos.fromJson(m)).toList();
      print("Lista de medicamentos: $medicamentos");
      return medicamentos;
    } else {
      throw Exception("Failed data");
    }
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
    fetchData().then((value) {
      loadModel().then((value) {
        setState(() {
          isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "App Medicamentos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? Container() : Image.file(_image!),
            SizedBox(
              height: 20,
            ),
            buildOutputText(),
            ElevatedButton(
              onPressed: () {
                pickImage();
              },
              child: const Text("Seleccionar imagen"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOutputText() {
    if (_outputs != null && _outputs!.isNotEmpty) {
      int detectedIndex = _outputs![0]["index"] + 1; // Ajuste del índice
      Medicamentos? medicamentoEncontrado = medicamentos.firstWhere(
            (med) => med.id == detectedIndex,
        orElse: () => Medicamentos(
          id: -1,
          nombre: "No encontrado",
          dosis: "",
          para_que_sirve: "",
          contraindicaciones: "",
        ),
      );
      return Text(
        medicamentoEncontrado.id != -1
            ? "${medicamentoEncontrado.nombre}\n"
            "${medicamentoEncontrado.dosis}\n"
            "${medicamentoEncontrado.para_que_sirve}\n"
            "${medicamentoEncontrado.contraindicaciones}\n"
            "Confianza: ${_outputs![0]["confidence"]}"
            : "Medicamento no encontrado",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      );
    } else {
      return Container();
    }
  }



  pickImage() async {
    final ImagePicker _picker = ImagePicker();
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }

    setState(() {
      _image = File(image.path.toString());
    });

    classifyImage(File(image.path));
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 10,
      threshold: 0.4,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    print('Resultado de clasificación: $output');

    setState(() {
      isLoading = false;
      _outputs = output;
    });

    print("Outputs: $_outputs");
    if (_outputs != null && _outputs!.isNotEmpty) {
      print("Índice detectado en outputs: ${_outputs![0]["index"]}");
    } else {
      print("No se encontraron outputs");
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }
}

class Medicamentos {
  Medicamentos({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.para_que_sirve,
    required this.contraindicaciones,
  });

  int id;
  String nombre;
  String dosis;
  String para_que_sirve;
  String contraindicaciones;

  Medicamentos.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        nombre = json['nombre'] ?? "",
        dosis = json['dosis'] ?? "",
        para_que_sirve = json['para_que_sirve'] ?? "",
        contraindicaciones = json['contraindicaciones'] ?? "";

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['nombre'] = this.nombre;
    data['dosis'] = this.dosis;
    data['para_que_sirve'] = this.para_que_sirve;
    data['contraindicaciones'] = this.contraindicaciones;

    return data;
  }
}
