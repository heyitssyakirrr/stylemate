import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  Interpreter? _interpreter;
  late Map<String, List<String>> _labelMaps;
  static const int INPUT_SIZE = 299;
  static const String MODEL_PATH = 'assets/ml_data/classifier_extractor.tflite';
  static const String LABELS_PATH = 'assets/ml_data/label_maps.json';

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // Add delegates if needed (e.g., GPUDelegate, XNNPackDelegate)
      // options.addDelegate(XNNPackDelegate()); 
      
      _interpreter = await Interpreter.fromAsset(MODEL_PATH, options: options);
      
      final labelJson = await rootBundle.loadString(LABELS_PATH);
      final decodedJson = json.decode(labelJson) as Map<String, dynamic>;
      _labelMaps = decodedJson.map((key, value) => MapEntry(key, (value as List).cast<String>()));
      
      print('✅ MLService: Model and labels loaded.');
      
      // Print output shapes for debugging
      var outputShapes = _interpreter!.getOutputTensors().map((e) => e.shape).toList();
      print("Model Output Shapes: $outputShapes");

    } catch (e) {
      print('❌ MLService Error: $e');
    }
  }

  // Preprocessing: Resize and normalize image to [1, 299, 299, 3]
  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    final rawImage = img.decodeImage(imageFile.readAsBytesSync())!;
    // Resize to 299x299 (ResNet50 input size)
    final resizedImage = img.copyResize(rawImage, width: INPUT_SIZE, height: INPUT_SIZE);

    // Create input tensor [1, 299, 299, 3]
    var input = List.generate(1, (i) => List.generate(INPUT_SIZE, (y) => List.generate(INPUT_SIZE, (x) => List.filled(3, 0.0))));

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Normalize pixel values to 0.0 - 1.0 (dividing by 255.0)
        // Note: Check if your model expects specific mean/std normalization. 
        // Simple scaling 0-1 is common but verify with your training logic.
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  Map<String, dynamic> classifyAndExtract(File imageFile) {
    if (_interpreter == null) throw Exception('Interpreter not initialized');

    // 1. Prepare Input
    var input = _preprocessImage(imageFile);

    // 2. Prepare Output Buffers
    // We need to map model outputs correctly.
    // Based on typical Keras export, one output is the embedding, and others are classification heads.
    // We allocate buffers for all outputs.
    var outputBuffer = <int, Object>{};
    for(int i=0; i< _interpreter!.getOutputCount(); i++) {
         int size = _interpreter!.getOutputTensor(i).shape.reduce((a, b) => a * b);
         // Allocate float list for each output
         outputBuffer[i] = List.filled(1, List.filled(size, 0.0));
    }

    // 3. Run Inference
    _interpreter!.runForMultipleInputs([input], outputBuffer);

    // 4. Parse Outputs
    // We identify the embedding vector by its size (2048).
    // Classification results are matched to label maps by size of output array.
    List<double> embedding = [];
    Map<String, String> predictions = {};
    
    // Helper to find index of max value
    int argmax(List<double> list) {
        if (list.isEmpty) return -1;
        double maxValue = list[0];
        int maxIndex = 0;
        for (int i = 1; i < list.length; i++) {
            if (list[i] > maxValue) {
                maxValue = list[i];
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    for(int i=0; i< _interpreter!.getOutputCount(); i++) {
        // Cast the output buffer to List<double>
        // Note: TFLite output might be nested List<List<double>> or flat List<double> depending on buffer shape
        // Usually [1, size] -> we take the first element [0] which is the List<double>
        var rawOutput = outputBuffer[i] as List;
        var tensorData = (rawOutput[0] as List).cast<double>();
        
        if (tensorData.length == 2048) {
            embedding = tensorData;
        } else {
            // Match with label maps based on size (number of classes)
            _labelMaps.forEach((key, labels) {
                if (labels.length == tensorData.length) {
                    int index = argmax(tensorData);
                    if (index != -1 && index < labels.length) {
                         predictions[key] = labels[index];
                    }
                }
            });
        }
    }

    return {
      'tags': predictions,
      'embedding': embedding,
    };
  }
}