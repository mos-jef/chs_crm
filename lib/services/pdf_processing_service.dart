// lib/services/pdf_processing_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PdfProcessingService {
  // Multiple service options for redundancy
  static const String _pdfCoParserId = 'jeffreyandersonpdx@gmail.com_5VEewaNIwIS0BDxZneIlQbmPgIzXkigiM21k5avjUMmIKWr4RvOoGfpXbwuBPKye';
  static const String _pdfCoUrl = 'https://api.pdf.co/v1/pdf/convert/to/text';
  
  /// Extract text from PDF using external service
  static Future<String> extractTextFromPdf(Uint8List pdfData, String filename) async {
    try {
      print('Processing PDF: $filename (${pdfData.length} bytes)');
      
      // Try primary service
      try {
        return await _extractUsingPdfCo(pdfData);
      } catch (e) {
        print('Primary PDF service failed: $e');
      }
      
      // Try fallback service
      try {
        return await _extractUsingILovePdf(pdfData);
      } catch (e) {
        print('Fallback PDF service failed: $e');
      }
      
      // Final fallback - manual text extraction
      return await _extractUsingManualParsing(pdfData);
      
    } catch (e) {
      throw Exception('All PDF processing methods failed: $e');
    }
  }

  /// Method 1: PDF.co service (reliable, has free tier)
  static Future<String> _extractUsingPdfCo(Uint8List pdfData) async {
    print('Sending request to PDF.co API...');

    // Step 1: Upload the file first
    final uploadResponse = await http.post(
      Uri.parse('https://api.pdf.co/v1/file/upload'),
      headers: {
        'Content-Type': 'application/octet-stream',
        'x-api-key': _pdfCoParserId,
      },
      body: pdfData,
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception(
          'PDF.co upload failed: ${uploadResponse.statusCode} - ${uploadResponse.body}');
    }

    final uploadResult = json.decode(uploadResponse.body);
    if (uploadResult['error'] == true) {
      throw Exception('PDF.co upload error: ${uploadResult['message']}');
    }

    final uploadedFileUrl = uploadResult['url'] as String;
    print('File uploaded successfully: $uploadedFileUrl');

    // Step 2: Process the uploaded file
    final response = await http.post(
      Uri.parse(_pdfCoUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _pdfCoParserId,
      },
      body: json.encode({
        'url': uploadedFileUrl,
        'pages': '0-10',
        'inline': true,
      }),
    );

    print('Processing response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['error'] == false) {
        // PDF.co returned structured JSON data, convert it to text format for parsing
        return _convertPdfCoJsonToText(result);
      } else {
        throw Exception('PDF.co error: ${result['message']}');
      }
    } else {
      throw Exception(
          'PDF.co API error: ${response.statusCode} - ${response.body}');
    }
  }

// New helper method to convert PDF.co JSON to parseable text
  static String _convertPdfCoJsonToText(Map<String, dynamic> pdfCoResult) {
    final buffer = StringBuffer();

    // Extract key fields that your parser expects
    final body = pdfCoResult['body'] as Map<String, dynamic>?;
    if (body != null && body['objects'] != null) {
      final objects = body['objects'] as List<dynamic>;

      // Find and format key data points
      for (final obj in objects) {
        if (obj['name'] == 'invoiceId' && obj['value'] != null) {
          buffer.writeln('Property ID: ${obj['value']}');
        }
        if (obj['name'] == 'total' && obj['value'] != null) {
          buffer.writeln('Total Due: \$${obj['value']}');
        }
      }

      // Extract table data for owner and address
      final tableData = objects.firstWhere(
          (obj) => obj['objectType'] == 'table',
          orElse: () => null);
      if (tableData != null && tableData['rows'] != null) {
        final rows = tableData['rows'] as List<dynamic>;

        for (final row in rows) {
          // Look for Owner Name
          if (row['column3'] != null &&
              row['column3']['value'] == 'Owner Name' &&
              row['column4'] != null &&
              row['column4']['value'] != null) {
            buffer.writeln('Owner Name ${row['column4']['value']}');
          }

          // Look for Mailing Address (which contains the property address)
          if (row['column3'] != null &&
              row['column3']['value'] == 'Mailing Address' &&
              row['column4'] != null &&
              row['column4']['value'] != null) {
            buffer.writeln('Property Address: ${row['column4']['value']}');
          }
        }
      }
    }

    final textResult = buffer.toString();
    print('Converted PDF.co JSON to text format:');
    print(textResult);

    return textResult;
  }

  /// Method 2: ILovePDF service (alternative)
  static Future<String> _extractUsingILovePdf(Uint8List pdfData) async {
    // This would require ILovePDF API setup
    // For demo purposes, throwing not implemented
    throw UnimplementedError('ILovePDF integration not configured');
  }

  /// Method 3: Manual parsing for Multnomah County PDFs specifically
  static Future<String> _extractUsingManualParsing(Uint8List pdfData) async {
    // For Multnomah County PDFs, we can try to extract key patterns
    // This is a fallback when services fail
    
    // Convert PDF to string representation (basic approach)
    final pdfString = String.fromCharCodes(pdfData);
    
    // Look for text patterns in PDF structure
    final textBlocks = <String>[];
    
    // Extract text between specific PDF markers
    final textMarkers = RegExp(r'\(([^)]+)\)', multiLine: true);
    final matches = textMarkers.allMatches(pdfString);
    
    for (final match in matches) {
      final text = match.group(1);
      if (text != null && text.length > 3) {
        textBlocks.add(text);
      }
    }
    
    if (textBlocks.isEmpty) {
      throw Exception('Could not extract any text from PDF');
    }
    
    return textBlocks.join(' ');
  }

  /// Free alternative using a serverless function
  static Future<String> extractUsingCloudFunction(Uint8List pdfData) async {
    const functionUrl = 'https://your-pdf-processor.vercel.app/api/extract-pdf';
    
    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: pdfData,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['text'] as String;
      } else {
        throw Exception('Cloud function error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cloud function failed: $e');
    }
  }
}

/// Complete PDF batch processor with UI feedback
class PdfBatchProcessor {
  static Future<BatchResult> processTaxStatementBatch({
    required BuildContext context,
    required List<PlatformFile> pdfFiles,
    required Function(String) onProgress,
  }) async {
    final results = <String, String>{};
    final errors = <String, String>{};
    
    for (int i = 0; i < pdfFiles.length; i++) {
      final file = pdfFiles[i];
      onProgress('Processing ${file.name} (${i + 1}/${pdfFiles.length})');
      
      try {
        final pdfData = file.bytes!;
        final extractedText = await PdfProcessingService.extractTextFromPdf(
          pdfData, 
          file.name
        );
        
        results[file.name] = extractedText;
        onProgress('✅ Completed ${file.name}');
        
      } catch (e) {
        errors[file.name] = e.toString();
        onProgress('❌ Failed ${file.name}: $e');
      }
      
      // Small delay to prevent overwhelming services
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return BatchResult(
      successCount: results.length,
      errorCount: errors.length,
      extractedTexts: results,
      errors: errors,
    );
  }
}

class BatchResult {
  final int successCount;
  final int errorCount;
  final Map<String, String> extractedTexts;
  final Map<String, String> errors;
  
  BatchResult({
    required this.successCount,
    required this.errorCount,
    required this.extractedTexts,
    required this.errors,
  });
  
  int get totalFiles => successCount + errorCount;
  double get successRate => totalFiles > 0 ? successCount / totalFiles : 0.0;
}
