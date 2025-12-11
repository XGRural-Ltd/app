import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class GCSUploader {
  final String bucketName = "tunetap_bucket";
  final String serviceAccountPath = "assets/service_account_gcp.json";

  Future<String?> uploadImage() async {
    // 1. Selecionar imagem
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();

    // 2. Carregar chave JSON da service account
    final serviceJson = await rootBundle.loadString(serviceAccountPath);
    final creds = ServiceAccountCredentials.fromJson(json.decode(serviceJson));

    // 3. Autenticação
    final client = await clientViaServiceAccount(
      creds,
      [gcs.StorageApi.devstorageFullControlScope],
    );

    final storage = gcs.StorageApi(client);

    final objectName = "uploads/${DateTime.now().millisecondsSinceEpoch}.jpg";

    // 4. Upload
    final media = gcs.Media(Stream.value(bytes), bytes.length);
    final object = gcs.Object(name: objectName);

    final uploaded = await storage.objects.insert(
      object,
      bucketName,
      uploadMedia: media,
    );

    client.close();

    // 5. Gerar URL pública (se o bucket permitir leitura pública)
    final publicUrl =
        "https://storage.googleapis.com/$bucketName/${uploaded.name}";

    return publicUrl;
  }
}


// final uploader = GCSUploader();

// void enviar() async {
//   final url = await uploader.uploadImage();

//   if (url != null) {
//     print("URL da imagem: $url");

//     // Exemplo de salvar no Firestore
//     // FirebaseFirestore.instance.collection("usuarios").add({
//     //   "foto": url,
//     // });

//   }
// }
