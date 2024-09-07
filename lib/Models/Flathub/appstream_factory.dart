import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_category.dart';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class AppStreamFactory {
  static const constTableAppStream = 'appstream';
  static const constTableCategory = 'category';
  static const constTableAppStreamCategory = 'category_appstream';

  late DatabaseFactory database;
  late Database db;
  bool isDbConnected = false;
  late String dbPath;

  Future<void> init() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();

    final appDocumentsDirPath = appDocumentsDir.path;
    dbPath = p.join(appDocumentsDirPath, "EasyFlatpak", "flathub_database.db");
  }

  Future<String> getPath() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();

    final appDocumentsDirPath = appDocumentsDir.path;
    return p.join(appDocumentsDirPath, "EasyFlatpak");
  }

  Future<void> connect() async {
    if (!isDbConnected) {
      await init();

      db = await databaseFactory.openDatabase(
        dbPath,
      );
      isDbConnected = true;
    }
  }

  Future<Database> getDb() async {
    await connect();
    return db;
  }

  Future<void> create() async {
    await init();

    if (!File(dbPath).existsSync()) {
      final db = await getDb();
      print('Error database does not exist');
/** 
      db.execute('''
      CREATE TABLE $constTableAppStream 
          (
          id TEXT PRIMARY KEY, 
          name TEXT, 
          summary TEXT, 
          icon TEXT, 
          projectLicense TEXT , 
          categoryIdList TEXT,
          description TEXT,
          metadataObj TEXT,
          urlObj TEXT, 
          releaseObjList TEXT,
          lastUpdate INTEGER,
          developer_name TEXT
          );
      CREATE TABLE category (id TEXT PRIMARY KEY) ; 
      CREATE TABLE category_appstream (  appstream_id TEXT, category_id TEXT, PRIMARY KEY (appstream_id, category_id))
      ''');

      List<String> categoryList = [
        "AudioVideo",
        "Development",
        "Education",
        "Game",
        "Graphics",
        "Network",
        "Office",
        "Science",
        "System",
        "Utility"
      ];
      for (String categoryLoop in categoryList) {
        await db
            .insert(constTableCategory, <String, Object?>{'id': categoryLoop});
      }
      */
    } else {
      print('database already exist');
    }
  }

  Future<bool> insertAppStream(AppStream appStream) async {
    final db = await getDb();
    db.insert(
      constTableAppStream,
      appStream.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return true;
  }

  Future<bool> insertAppStreamList(List<AppStream> appStreamList) async {
    final db = await getDb();

    await db.transaction((txn) async {
      var batch = txn.batch();
      for (AppStream appStreamLoop in appStreamList) {
        try {
          batch.insert(constTableAppStream, appStreamLoop.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (exception) {
          throw "some error while insertion";
        }
      }
      await batch.commit(continueOnError: false, noResult: true);
    });

    return true;
  }

  Future<List<String>> findAllCategoryList() async {
    final db = await getDb();
    final List<Map<String, Object?>> rawCategoryList =
        await db.query(constTableCategory);

    return [for (final {'id': id as String} in rawCategoryList) id];
  }

  Future<List<AppStream>> findAllAppStream() async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList =
        await db.query(constTableAppStream);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'description': description as String,
            'lastUpdate': lastUpdate as int
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: description,
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: ''),
    ];
  }

  Future<AppStream> findAppStreamById(String id) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db
        .rawQuery('SELECT * FROM $constTableAppStream WHERE id=?', [id]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    List<AppStream> rowList = [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'description': description as String,
            'lastUpdate': lastUpdate as int,
            'urlObj': urlObjString as String,
            'projectLicense': projectLicense as String,
            'developer_name': developer_name as String,
            'metadataObj': metadataObjString as String
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: description,
            lastUpdate: lastUpdate,
            metadataObj: jsonDecode(metadataObjString),
            releaseObjList: [],
            urlObj: jsonDecode(urlObjString),
            projectLicense: projectLicense,
            developer_name: developer_name),
    ];

    return rowList[0];
  }

  Future<List<String>> findAllApplicationIdList() async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db
        .rawQuery('SELECT $constTableAppStream.id from $constTableAppStream ');

    List<String> applicationIdList = [];
    for (Map<String, dynamic> rawAppStreamLoop in appStreamList) {
      applicationIdList.add(rawAppStreamLoop['id'].toString().toLowerCase());
    }
    return applicationIdList;
  }

  Future<List<AppStream>> findListAppStreamByIdList(
      List<String> applicationIdList) async {
    final db = await getDb();

    List<String> whereApplicationIdStringList = [];
    for (String applicationIdLoop in applicationIdList) {
      whereApplicationIdStringList.add("'$applicationIdLoop'");
    }

    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db.rawQuery(
        '''SELECT distinct $constTableAppStream.id,$constTableAppStream.name,$constTableAppStream.summary,$constTableAppStream.icon,$constTableAppStream.lastUpdate from $constTableAppStream INNER JOIN $constTableAppStreamCategory ON $constTableAppStream.id=$constTableAppStreamCategory.appstream_id 
        where id in (${whereApplicationIdStringList.join(',')}) ORDER by name asc''',
        []);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: ''),
    ];
  }

  Future<List<AppStream>> findListAppStreamByCategory(String categoryId) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db.rawQuery(
        'SELECT $constTableAppStream.id,$constTableAppStream.name,$constTableAppStream.summary,$constTableAppStream.icon,$constTableAppStream.lastUpdate from $constTableAppStream INNER JOIN $constTableAppStreamCategory ON $constTableAppStream.id=$constTableAppStreamCategory.appstream_id where category_id=? ORDER by name asc',
        [categoryId]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: ''),
    ];
  }

  Future<List<AppStream>> findListAppStreamBySearch(String search) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db.rawQuery(
      'SELECT $constTableAppStream.id,$constTableAppStream.name,$constTableAppStream.summary,$constTableAppStream.icon,$constTableAppStream.lastUpdate from $constTableAppStream  where name like \'%$search%\' or summary like \'%$search%\'  ORDER by name asc',
    );

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: ''),
    ];
  }

  Future<List<AppStream>> findListAppStreamByCategoryLimited(
      String categoryId, int limit) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> appStreamList = await db.rawQuery(
        'SELECT $constTableAppStream.id,$constTableAppStream.name,$constTableAppStream.summary,$constTableAppStream.icon,$constTableAppStream.lastUpdate from $constTableAppStream INNER JOIN $constTableAppStreamCategory ON $constTableAppStream.id=$constTableAppStreamCategory.appstream_id where category_id=? ORDER by name asc LIMIT $limit',
        [categoryId]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int
          } in appStreamList)
        AppStream(
            id: id,
            name: name,
            summary: summary,
            icon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: ''),
    ];
  }

  Future<bool> insertCategory(String category) async {
    final db = await getDb();
    db.insert(
      constTableCategory,
      {'id': category},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return true;
  }

  Future<bool> insertAppStreamCategory(
      String appStream, String category) async {
    final db = await getDb();
    db.insert(
      constTableAppStreamCategory,
      {'appstream_id': appStream, 'category_id': category},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return true;
  }

  Future<bool> insertAppStreamCategoryList(
      List<AppStreamCategory> appStreamCategoryList) async {
    final db = await getDb();
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (AppStreamCategory appStreamCategoryLoop in appStreamCategoryList) {
        try {
          batch.insert(
              constTableAppStreamCategory, appStreamCategoryLoop.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (exception) {
          throw "some error while insertion";
        }
      }
      await batch.commit(continueOnError: false);
    });

    return true;
  }

/*
  Future<void> update(AppStream dog) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Dog.
    await db.update(
      'dogs',
      dog.toMap(),
      // Ensure that the Dog has a matching id.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [dog.id],
    );
  }
  */

  void dispose() async {
    final db = await getDb();
    await db.close();
  }
}
