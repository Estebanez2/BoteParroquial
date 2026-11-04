import 'dart:io';
import 'package:bote_parroquial/services/device_photo_picker_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Editar bytes guardados crea temporal válido, recorta avatar circular/portada 16:9 y conserva la fuente',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'bote-photo-edit-test-',
      );
      final keep = File('${root.path}/original.keep');
      await keep.writeAsString('untouched');
      const channel = MethodChannel('plugins.hunghd.vn/image_cropper');
      final calls = <Map>[];
      var cancel = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'cropImage');
            final args = Map.from(call.arguments as Map);
            calls.add(args);
            final source = File(args['source_path'] as String);
            expect(await source.exists(), true);
            expect(source.parent.parent.absolute.path, root.absolute.path);
            return cancel ? null : source.path;
          });
      try {
        final service = DevicePhotoPickerService(
          ImagePicker(),
          temporaryDirectory: () async => root,
        );
        final bytes = image.encodePng(image.Image(width: 24, height: 24));
        expect(await service.edit(bytes), isNull);
        expect(calls.last['android.crop_style'], 'circle');
        expect(calls.last['ios.crop_style'], 'circle');
        cancel = false;
        final edited = await service.edit(bytes);
        expect(image.decodeImage(edited!)!.width, 1024);
        expect(calls.last['ratio_x'], 1);
        expect(calls.last['ratio_y'], 1);
        await service.edit(bytes, panoramic: true);
        expect(calls.last['android.crop_style'], 'rectangle');
        expect(calls.last['ios.crop_style'], 'rectangle');
        expect(calls.last['ratio_x'], 16);
        expect(calls.last['ratio_y'], 9);
        expect(await keep.readAsString(), 'untouched');
        expect((await root.list().toList()).length, 1);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        expect(root.absolute.parent.path, Directory.systemTemp.absolute.path);
        await root.delete(recursive: true);
      }
    },
  );
}
