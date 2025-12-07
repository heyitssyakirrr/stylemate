import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  Interpreter? _interpreter;
  late Map<String, List<String>> _labelMaps;
  static const int INPUT_SIZE = 299; // ResNet50 standard input
  
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml_data/classifier_extractor.tflite');
      final labelJson = await rootBundle.loadString('assets/ml_data/label_maps.json');
      final decoded = json.decode(labelJson) as Map<String, dynamic>;
      _labelMaps = decoded.map((key, value) => MapEntry(key, (value as List).cast<String>()));
      print("✅ ML Model Loaded");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  // Helper: Find index of maximum value
  int argmax(List<double> list) {
    if (list.isEmpty) return -1;
    double maxVal = list[0];
    int maxIdx = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxVal) {
        maxVal = list[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  Map<String, dynamic> classifyAndExtract(File imageFile) {
    if (_interpreter == null) throw Exception("Model not loaded");

    // 1. Preprocess Image
    final rawImage = img.decodeImage(imageFile.readAsBytesSync())!;
    final resized = img.copyResize(rawImage, width: INPUT_SIZE, height: INPUT_SIZE);
    
    // Normalize [0, 255] -> [0.0, 1.0] and shape to [1, 299, 299, 3]
    var input = List.generate(1, (i) => List.generate(INPUT_SIZE, (y) => List.generate(INPUT_SIZE, (x) => List.filled(3, 0.0))));
    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    // 2. Prepare Outputs
    // Get the list of output tensors once to avoid repeated calls
    final outputTensors = _interpreter!.getOutputTensors();
    var outputBuffers = <int, Object>{};
    
    // FIX: Using .length of the tensor list
    for (int i = 0; i < outputTensors.length; i++) {
      // FIX: Accessing tensor from the list instead of getOutputTensor(i)
      int shapeSize = outputTensors[i].shape.reduce((a, b) => a * b);
      outputBuffers[i] = List.filled(1, List.filled(shapeSize, 0.0));
    }

    // 3. Run Inference
    _interpreter!.runForMultipleInputs([input], outputBuffers);

    // 4. Parse Results
    List<double> embedding = [];
    Map<String, String> tags = {};

    // FIX: Using .length again for consistency
    for (int i = 0; i < outputTensors.length; i++) {
      var rawOut = outputBuffers[i] as List;
      var data = (rawOut[0] as List).cast<double>();

      if (data.length == 2048) {
        embedding = data;
      } else {
        // Try to match with label maps based on size
        _labelMaps.forEach((key, labels) {
          if (labels.length == data.length) {
            tags[key] = labels[argmax(data)];
          }
        });
      }
    }

    return {'tags': tags, 'embedding': embedding};
  }
}