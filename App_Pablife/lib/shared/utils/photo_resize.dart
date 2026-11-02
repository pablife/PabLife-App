import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Lado maior da foto de perfil enviada. As telas mostram a foto em no
/// máximo uns 200 px; 600 dá folga para telas de alta densidade.
const int profilePhotoMaxSide = 600;

/// Reduz a foto de perfil antes do envio: fotos de celular chegam com vários
/// MB e deixavam a lista de profissionais lenta para carregar.
///
/// Devolve JPEG com a rotação da câmera já aplicada. Se a imagem não puder
/// ser lida, devolve os bytes originais.
Uint8List shrinkProfilePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  var photo = img.bakeOrientation(decoded);
  final longest = photo.width > photo.height ? photo.width : photo.height;
  if (longest > profilePhotoMaxSide) {
    photo = photo.width >= photo.height
        ? img.copyResize(photo, width: profilePhotoMaxSide,
            interpolation: img.Interpolation.average)
        : img.copyResize(photo, height: profilePhotoMaxSide,
            interpolation: img.Interpolation.average);
  }
  return img.encodeJpg(photo, quality: 85);
}

/// Troca a extensão do nome do arquivo para .jpg, já que a foto reduzida
/// sempre sai em JPEG.
String jpgFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return '${dot > 0 ? fileName.substring(0, dot) : fileName}.jpg';
}
