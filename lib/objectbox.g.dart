// GENERATED CODE - DO NOT MODIFY BY HAND

// Currently loading model from "JSON" which always encodes with double quotes
// ignore_for_file: prefer_single_quotes
// ignore_for_file: camel_case_types

import 'dart:typed_data';

import 'package:objectbox/flatbuffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart';

import 'crypto/signal/vo/Identity.dart';
import 'crypto/signal/vo/PreKey.dart';
import 'crypto/signal/vo/SenderKey.dart';
import 'crypto/signal/vo/Session.dart';
import 'crypto/signal/vo/SignedPreKey.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

ModelDefinition getObjectBoxModel() {
  final model = ModelInfo.fromMap({
    "entities": [
      {
        "id": "1:7719677999600064814",
        "lastPropertyId": "7:3664078409729265392",
        "name": "Identity",
        "properties": [
          {
            "id": "1:5801125836071890945",
            "name": "id",
            "type": 6,
            "flags": 1,
            "dartFieldType": "int"
          },
          {
            "id": "2:1207953105356381474",
            "name": "address",
            "type": 9,
            "dartFieldType": "String"
          },
          {
            "id": "3:960808382367841437",
            "name": "registration_id",
            "type": 6,
            "dartFieldType": "int?"
          },
          {
            "id": "4:6387182472869229612",
            "name": "public_key",
            "type": 23,
            "dartFieldType": "Uint8List"
          },
          {
            "id": "5:827547181159261866",
            "name": "private_key",
            "type": 23,
            "dartFieldType": "Uint8List?"
          },
          {
            "id": "6:6450251074243179355",
            "name": "next_prekey_id",
            "type": 6,
            "dartFieldType": "int?"
          },
          {
            "id": "7:3664078409729265392",
            "name": "date",
            "type": 10,
            "dartFieldType": "DateTime"
          }
        ],
        "relations": [],
        "backlinks": [],
        "constructorParams": [
          "address positional",
          "public_key positional",
          "date positional",
          "registration_id named",
          "private_key named",
          "next_prekey_id named"
        ],
        "nullSafetyEnabled": true
      },
      {
        "id": "2:7423204204614724244",
        "lastPropertyId": "3:6203029340822498001",
        "name": "PreKey",
        "properties": [
          {
            "id": "1:1370784781958777248",
            "name": "id",
            "type": 6,
            "flags": 1,
            "dartFieldType": "int"
          },
          {
            "id": "2:4485147644125446886",
            "name": "preKeyId",
            "type": 6,
            "dartFieldType": "int"
          },
          {
            "id": "3:6203029340822498001",
            "name": "record",
            "type": 23,
            "dartFieldType": "Uint8List"
          }
        ],
        "relations": [],
        "backlinks": [],
        "constructorParams": [],
        "nullSafetyEnabled": true
      },
      {
        "id": "3:3481321293384307445",
        "lastPropertyId": "5:5614346873261449739",
        "name": "Session",
        "properties": [
          {
            "id": "1:8131297425341389028",
            "name": "id",
            "type": 6,
            "flags": 1,
            "dartFieldType": "int"
          },
          {
            "id": "2:6877131952813598768",
            "name": "address",
            "type": 9,
            "dartFieldType": "String"
          },
          {
            "id": "3:1734492263621574535",
            "name": "device",
            "type": 6,
            "dartFieldType": "int"
          },
          {
            "id": "4:782971937429408563",
            "name": "record",
            "type": 23,
            "dartFieldType": "Uint8List"
          },
          {
            "id": "5:5614346873261449739",
            "name": "date",
            "type": 10,
            "dartFieldType": "DateTime"
          }
        ],
        "relations": [],
        "backlinks": [],
        "constructorParams": [],
        "nullSafetyEnabled": true
      },
      {
        "id": "4:3688591859747244472",
        "lastPropertyId": "4:7544146986359602937",
        "name": "SignedPreKey",
        "properties": [
          {
            "id": "1:8552982886381529018",
            "name": "id",
            "type": 6,
            "flags": 1,
            "dartFieldType": "int"
          },
          {
            "id": "2:2972445176547876059",
            "name": "preKeyId",
            "type": 6,
            "dartFieldType": "int"
          },
          {
            "id": "3:606757744333170830",
            "name": "record",
            "type": 23,
            "dartFieldType": "Uint8List"
          },
          {
            "id": "4:7544146986359602937",
            "name": "timestamp",
            "type": 10,
            "dartFieldType": "DateTime"
          }
        ],
        "relations": [],
        "backlinks": [],
        "constructorParams": [],
        "nullSafetyEnabled": true
      },
      {
        "id": "5:7389426397347176584",
        "lastPropertyId": "4:5476360411632178006",
        "name": "SenderKey",
        "properties": [
          {
            "id": "1:2161129945215296810",
            "name": "id",
            "type": 6,
            "flags": 1,
            "dartFieldType": "int"
          },
          {
            "id": "2:1002426951589442728",
            "name": "groupId",
            "type": 9,
            "dartFieldType": "String"
          },
          {
            "id": "3:6402232570517008596",
            "name": "senderId",
            "type": 9,
            "dartFieldType": "String"
          },
          {
            "id": "4:5476360411632178006",
            "name": "record",
            "type": 23,
            "dartFieldType": "Uint8List"
          }
        ],
        "relations": [],
        "backlinks": [],
        "constructorParams": [
          "groupId positional",
          "senderId positional",
          "record positional"
        ],
        "nullSafetyEnabled": true
      }
    ],
    "lastEntityId": "5:7389426397347176584",
    "lastIndexId": "0:0",
    "lastRelationId": "0:0",
    "lastSequenceId": "0:0",
    "modelVersion": 5
  }, check: false);

  final bindings = <Type, EntityDefinition>{};
  bindings[Identity] = EntityDefinition<Identity>(
      model: model.getEntityByUid(7719677999600064814),
      toOneRelations: (Identity object) => [],
      toManyRelations: (Identity object) => {},
      getId: (Identity object) => object.id,
      setId: (Identity object, int id) {
        object.id = id;
      },
      objectToFB: (Identity object, fb.Builder fbb) {
        final addressOffset = fbb.writeString(object.address);
        final public_keyOffset = fbb.writeListInt8(object.public_key);
        final private_keyOffset = object.private_key == null
            ? null
            : fbb.writeListInt8(object.private_key!);
        fbb.startTable(8);
        fbb.addInt64(0, object.id);
        fbb.addOffset(1, addressOffset);
        fbb.addInt64(2, object.registration_id);
        fbb.addOffset(3, public_keyOffset);
        fbb.addOffset(4, private_keyOffset);
        fbb.addInt64(5, object.next_prekey_id);
        fbb.addInt64(6, object.date.millisecondsSinceEpoch);
        fbb.finish(fbb.endTable());
        return object.id;
      },
      objectFromFB: (Store store, Uint8List fbData) {
        final buffer = fb.BufferContext.fromBytes(fbData);
        final rootOffset = buffer.derefObject(0);
        final private_keyValue = const fb.ListReader<int>(fb.Int8Reader())
            .vTableGetNullable(buffer, rootOffset, 12);
        final object = Identity(
            const fb.StringReader().vTableGet(buffer, rootOffset, 6, ''),
            Uint8List.fromList(const fb.ListReader<int>(fb.Int8Reader())
                .vTableGet(buffer, rootOffset, 10, [])),
            DateTime.fromMillisecondsSinceEpoch(
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 16, 0)),
            registration_id:
                const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 8),
            private_key: private_keyValue == null
                ? null
                : Uint8List.fromList(private_keyValue),
            next_prekey_id: const fb.Int64Reader()
                .vTableGetNullable(buffer, rootOffset, 14))
          ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

        return object;
      });
  bindings[PreKey] = EntityDefinition<PreKey>(
      model: model.getEntityByUid(7423204204614724244),
      toOneRelations: (PreKey object) => [],
      toManyRelations: (PreKey object) => {},
      getId: (PreKey object) => object.id,
      setId: (PreKey object, int id) {
        object.id = id;
      },
      objectToFB: (PreKey object, fb.Builder fbb) {
        final recordOffset = fbb.writeListInt8(object.record);
        fbb.startTable(4);
        fbb.addInt64(0, object.id);
        fbb.addInt64(1, object.preKeyId);
        fbb.addOffset(2, recordOffset);
        fbb.finish(fbb.endTable());
        return object.id;
      },
      objectFromFB: (Store store, Uint8List fbData) {
        final buffer = fb.BufferContext.fromBytes(fbData);
        final rootOffset = buffer.derefObject(0);

        final object = PreKey()
          ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
          ..preKeyId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0)
          ..record = Uint8List.fromList(
              const fb.ListReader<int>(fb.Int8Reader())
                  .vTableGet(buffer, rootOffset, 8, []));

        return object;
      });
  bindings[Session] = EntityDefinition<Session>(
      model: model.getEntityByUid(3481321293384307445),
      toOneRelations: (Session object) => [],
      toManyRelations: (Session object) => {},
      getId: (Session object) => object.id,
      setId: (Session object, int id) {
        object.id = id;
      },
      objectToFB: (Session object, fb.Builder fbb) {
        final addressOffset = fbb.writeString(object.address);
        final recordOffset = fbb.writeListInt8(object.record);
        fbb.startTable(6);
        fbb.addInt64(0, object.id);
        fbb.addOffset(1, addressOffset);
        fbb.addInt64(2, object.device);
        fbb.addOffset(3, recordOffset);
        fbb.addInt64(4, object.date.millisecondsSinceEpoch);
        fbb.finish(fbb.endTable());
        return object.id;
      },
      objectFromFB: (Store store, Uint8List fbData) {
        final buffer = fb.BufferContext.fromBytes(fbData);
        final rootOffset = buffer.derefObject(0);

        final object = Session()
          ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
          ..address =
              const fb.StringReader().vTableGet(buffer, rootOffset, 6, '')
          ..device = const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0)
          ..record = Uint8List.fromList(
              const fb.ListReader<int>(fb.Int8Reader())
                  .vTableGet(buffer, rootOffset, 10, []))
          ..date = DateTime.fromMillisecondsSinceEpoch(
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0));

        return object;
      });
  bindings[SignedPreKey] = EntityDefinition<SignedPreKey>(
      model: model.getEntityByUid(3688591859747244472),
      toOneRelations: (SignedPreKey object) => [],
      toManyRelations: (SignedPreKey object) => {},
      getId: (SignedPreKey object) => object.id,
      setId: (SignedPreKey object, int id) {
        object.id = id;
      },
      objectToFB: (SignedPreKey object, fb.Builder fbb) {
        final recordOffset = fbb.writeListInt8(object.record);
        fbb.startTable(5);
        fbb.addInt64(0, object.id);
        fbb.addInt64(1, object.preKeyId);
        fbb.addOffset(2, recordOffset);
        fbb.addInt64(3, object.timestamp.millisecondsSinceEpoch);
        fbb.finish(fbb.endTable());
        return object.id;
      },
      objectFromFB: (Store store, Uint8List fbData) {
        final buffer = fb.BufferContext.fromBytes(fbData);
        final rootOffset = buffer.derefObject(0);

        final object = SignedPreKey()
          ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
          ..preKeyId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0)
          ..record = Uint8List.fromList(
              const fb.ListReader<int>(fb.Int8Reader())
                  .vTableGet(buffer, rootOffset, 8, []))
          ..timestamp = DateTime.fromMillisecondsSinceEpoch(
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0));

        return object;
      });
  bindings[SenderKey] = EntityDefinition<SenderKey>(
      model: model.getEntityByUid(7389426397347176584),
      toOneRelations: (SenderKey object) => [],
      toManyRelations: (SenderKey object) => {},
      getId: (SenderKey object) => object.id,
      setId: (SenderKey object, int id) {
        object.id = id;
      },
      objectToFB: (SenderKey object, fb.Builder fbb) {
        final groupIdOffset = fbb.writeString(object.groupId);
        final senderIdOffset = fbb.writeString(object.senderId);
        final recordOffset = fbb.writeListInt8(object.record);
        fbb.startTable(5);
        fbb.addInt64(0, object.id);
        fbb.addOffset(1, groupIdOffset);
        fbb.addOffset(2, senderIdOffset);
        fbb.addOffset(3, recordOffset);
        fbb.finish(fbb.endTable());
        return object.id;
      },
      objectFromFB: (Store store, Uint8List fbData) {
        final buffer = fb.BufferContext.fromBytes(fbData);
        final rootOffset = buffer.derefObject(0);

        final object = SenderKey(
            const fb.StringReader().vTableGet(buffer, rootOffset, 6, ''),
            const fb.StringReader().vTableGet(buffer, rootOffset, 8, ''),
            Uint8List.fromList(const fb.ListReader<int>(fb.Int8Reader())
                .vTableGet(buffer, rootOffset, 10, [])))
          ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

        return object;
      });

  return ModelDefinition(model, bindings);
}

class Identity_ {
  static final id =
      QueryIntegerProperty(entityId: 1, propertyId: 1, obxType: 6);
  static final address =
      QueryStringProperty(entityId: 1, propertyId: 2, obxType: 9);
  static final registration_id =
      QueryIntegerProperty(entityId: 1, propertyId: 3, obxType: 6);
  static final public_key =
      QueryByteVectorProperty(entityId: 1, propertyId: 4, obxType: 23);
  static final private_key =
      QueryByteVectorProperty(entityId: 1, propertyId: 5, obxType: 23);
  static final next_prekey_id =
      QueryIntegerProperty(entityId: 1, propertyId: 6, obxType: 6);
  static final date =
      QueryIntegerProperty(entityId: 1, propertyId: 7, obxType: 10);
}

class PreKey_ {
  static final id =
      QueryIntegerProperty(entityId: 2, propertyId: 1, obxType: 6);
  static final preKeyId =
      QueryIntegerProperty(entityId: 2, propertyId: 2, obxType: 6);
  static final record =
      QueryByteVectorProperty(entityId: 2, propertyId: 3, obxType: 23);
}

class Session_ {
  static final id =
      QueryIntegerProperty(entityId: 3, propertyId: 1, obxType: 6);
  static final address =
      QueryStringProperty(entityId: 3, propertyId: 2, obxType: 9);
  static final device =
      QueryIntegerProperty(entityId: 3, propertyId: 3, obxType: 6);
  static final record =
      QueryByteVectorProperty(entityId: 3, propertyId: 4, obxType: 23);
  static final date =
      QueryIntegerProperty(entityId: 3, propertyId: 5, obxType: 10);
}

class SignedPreKey_ {
  static final id =
      QueryIntegerProperty(entityId: 4, propertyId: 1, obxType: 6);
  static final preKeyId =
      QueryIntegerProperty(entityId: 4, propertyId: 2, obxType: 6);
  static final record =
      QueryByteVectorProperty(entityId: 4, propertyId: 3, obxType: 23);
  static final timestamp =
      QueryIntegerProperty(entityId: 4, propertyId: 4, obxType: 10);
}

class SenderKey_ {
  static final id =
      QueryIntegerProperty(entityId: 5, propertyId: 1, obxType: 6);
  static final groupId =
      QueryStringProperty(entityId: 5, propertyId: 2, obxType: 9);
  static final senderId =
      QueryStringProperty(entityId: 5, propertyId: 3, obxType: 9);
  static final record =
      QueryByteVectorProperty(entityId: 5, propertyId: 4, obxType: 23);
}
