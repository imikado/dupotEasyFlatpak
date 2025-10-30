// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_category_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/path_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ApplicationRepository {
  static const constTableApplication = 'appstream';
  static const constTableCategory = 'category';
  static const constTableApplicationCategory = 'category_appstream';

  late DatabaseFactory database;
  late Database db;
  bool isDbConnected = false;
  late String dbPath;

  Future<void> init() async {
    dbPath = PathApi.getDbCachePath();
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

  Future<bool> insertApplicationEntity(
      ApplicationEntity applicationEntity) async {
    final db = await getDb();
    db.insert(
      constTableApplication,
      applicationEntity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return true;
  }

  Future<bool> insertApplicationEntityList(
      List<ApplicationEntity> applicationEntityList) async {
    final db = await getDb();

    await db.transaction((txn) async {
      var batch = txn.batch();
      for (ApplicationEntity applicationEntityLoop in applicationEntityList) {
        try {
          batch.insert(constTableApplication, applicationEntityLoop.toMap(),
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

  Future<List<ApplicationEntity>> findAllApplicationEntity() async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> applicationEntityList =
        await db.query(constTableApplication);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'description': description as String,
            'lastUpdate': lastUpdate as int,
            'lastReleaseTimestamp': lastReleaseTimestamp as int
          } in applicationEntityList)
        ApplicationEntity(
            id: id,
            name: name,
            summary: summary,
            httpIcon: icon,
            categoryIdList: [],
            description: description,
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: lastReleaseTimestamp),
    ];
  }

  Future<ApplicationEntity> findApplicationEntityById(String id) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> applicationEntityList = await db
        .rawQuery('SELECT * FROM $constTableApplication WHERE id=?', [id]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    List<ApplicationEntity> rowList = [
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
            'metadataObj': metadataObjString as String,
            'releaseObjList': releaseObjListString as String,
            'screenshotList': screenshotObjString as String,
            'lastReleaseTimestamp': lastReleaseTimestamp as int
          } in applicationEntityList)
        ApplicationEntity(
            id: id,
            name: name,
            summary: summary,
            httpIcon: icon,
            categoryIdList: [],
            description: description,
            lastUpdate: lastUpdate,
            metadataObj: jsonDecode(metadataObjString),
            releaseObjList: jsonDecode(releaseObjListString),
            urlObj: jsonDecode(urlObjString),
            projectLicense: projectLicense,
            developer_name: developer_name,
            screenshotObjList: jsonDecode(screenshotObjString) as List<dynamic>,
            lastReleaseTimestamp: lastReleaseTimestamp),
    ];

    if (rowList.isEmpty) {
      return ApplicationEntity(
          id: id,
          name: id,
          summary: 'Summary',
          httpIcon: '',
          categoryIdList: [],
          description: 'local .flatpak',
          lastUpdate: 0,
          metadataObj: {},
          releaseObjList: [],
          urlObj: {},
          projectLicense: '',
          developer_name: 'unknown',
          screenshotObjList: [],
          lastReleaseTimestamp: 0);
    }

    return rowList[0];
  }

  Future<void> deleteApplicationId(String applicationId) async {
    final db = await getDb();
    await db.rawDelete(
        'DELETE FROM $constTableApplication WHERE id = ?', [applicationId]);
  }

  Future<List<String>> findAllApplicationIdList() async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> applicationEntityList = await db.rawQuery(
        'SELECT $constTableApplication.id from $constTableApplication ');

    List<String> applicationIdList = [];
    for (Map<String, dynamic> rawApplicationEntityLoop
        in applicationEntityList) {
      applicationIdList
          .add(rawApplicationEntityLoop['id'].toString().toLowerCase());
    }
    return applicationIdList;
  }

  Future<List<ApplicationEntity>> findListApplicationEntityByIdList(
      List<String> applicationIdList) async {
    final db = await getDb();

    List<String> whereApplicationIdStringList = [];
    for (String applicationIdLoop in applicationIdList) {
      whereApplicationIdStringList.add("'${applicationIdLoop.toLowerCase()}'");
    }

    // Query the table for all the dogs.
    final List<
        Map<String,
            Object?>> rawApplicationEntityList = await db.rawQuery(
        '''SELECT distinct $constTableApplication.id,$constTableApplication.name,$constTableApplication.summary,$constTableApplication.icon,$constTableApplication.lastUpdate,$constTableApplication.lastReleaseTimestamp from $constTableApplication   
        where LOWER(id) in (${whereApplicationIdStringList.join(',')}) ORDER by name asc''',
        []);

    List<ApplicationEntity> applicationEntityList = [];

    for (final {
          'id': id as String,
          'name': name as String,
          'summary': summary as String,
          'icon': icon as String,
          'lastUpdate': lastUpdate as int,
          'lastReleaseTimestamp': lastReleaseTimestamp as int
        } in rawApplicationEntityList) {
      applicationIdList.remove(id);
      applicationIdList.remove(id.toLowerCase());

      applicationEntityList.add(ApplicationEntity(
          id: id,
          name: name,
          summary: summary,
          httpIcon: icon,
          categoryIdList: [],
          description: '',
          lastUpdate: lastUpdate,
          metadataObj: {},
          releaseObjList: [],
          urlObj: {},
          projectLicense: '',
          developer_name: '',
          screenshotObjList: [],
          lastReleaseTimestamp: lastReleaseTimestamp));
    }

    for (String idLoop in applicationIdList) {
      if (!idLoop.startsWith('org.freedesktop') &&
          !idLoop.startsWith('org.winehq.wine.') &&
          !idLoop.startsWith('org.gtk.gtk3theme') &&
          !idLoop.startsWith('org.gnome.sdk') &&
          idLoop.isNotEmpty &&
          !idLoop.contains('.platform')) {
        applicationEntityList.add(ApplicationEntity(
            id: idLoop,
            name: idLoop,
            summary: 'local installation',
            httpIcon: '',
            categoryIdList: [],
            description: '',
            lastUpdate: 0,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: 0));
      }
    }

    return applicationEntityList;
  }

  Future<List<ApplicationEntity>> findListApplicationEntityByCategory(
      String categoryId) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> rawApplicationList = await db.rawQuery(
        'SELECT $constTableApplication.id,$constTableApplication.name,$constTableApplication.summary,$constTableApplication.icon,$constTableApplication.lastUpdate,$constTableApplication.lastReleaseTimestamp from $constTableApplication INNER JOIN $constTableApplicationCategory ON $constTableApplication.id=$constTableApplicationCategory.appstream_id where category_id=? ORDER by name asc',
        [categoryId]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int,
            'lastReleaseTimestamp': lastReleaseTimestamp as int
          } in rawApplicationList)
        ApplicationEntity(
            id: id,
            name: name,
            summary: summary,
            httpIcon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: lastReleaseTimestamp),
    ];
  }

  Future<List<ApplicationEntity>> findListApplicationEntityBySearch(
      String search) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> rawApplicationList = await db.rawQuery(
      '''
        SELECT 
          $constTableApplication.id,
          $constTableApplication.name,
          $constTableApplication.summary,
          $constTableApplication.icon,
          $constTableApplication.lastUpdate,
          $constTableApplication.lastReleaseTimestamp 
          
          from $constTableApplication  
          
          where name like  '%$search%' 

 
        UNION ALL

           SELECT 
          $constTableApplication.id,
          $constTableApplication.name,
          $constTableApplication.summary,
          $constTableApplication.icon,
          $constTableApplication.lastUpdate,
          $constTableApplication.lastReleaseTimestamp 
          
          from $constTableApplication  
          
          where summary like  '%$search%'

        UNION ALL

           SELECT 
          $constTableApplication.id,
          $constTableApplication.name,
          $constTableApplication.summary,
          $constTableApplication.icon,
          $constTableApplication.lastUpdate,
          $constTableApplication.lastReleaseTimestamp 
          
          from $constTableApplication  
          
          where description like  '%$search%'   

 
        ''',
    );

    List<String> appIdList = [];

    final List<ApplicationEntity> distinctApplicationEntityList = [];
    for (final {
          'id': id as String,
          'name': name as String,
          'summary': summary as String,
          'icon': icon as String,
          'lastUpdate': lastUpdate as int,
          'lastReleaseTimestamp': lastReleaseTimestamp as int
        } in rawApplicationList) {
      if (appIdList.contains(id)) {
        continue;
      }

      distinctApplicationEntityList.add(ApplicationEntity(
          id: id,
          name: name,
          summary: summary,
          httpIcon: icon,
          categoryIdList: [],
          description: '',
          lastUpdate: lastUpdate,
          metadataObj: {},
          releaseObjList: [],
          urlObj: {},
          projectLicense: '',
          developer_name: '',
          screenshotObjList: [],
          lastReleaseTimestamp: lastReleaseTimestamp));

      appIdList.add(id);
    }

    return distinctApplicationEntityList;
  }

  Future<List<ApplicationEntity>>
      findListApplicationEntityByCategoryOrderedAndLimited(
          String categoryId, int limit) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> ApplicationEntityList = await db.rawQuery(
        'SELECT $constTableApplication.id,$constTableApplication.name,$constTableApplication.summary,$constTableApplication.icon,$constTableApplication.lastUpdate,$constTableApplication.lastReleaseTimestamp from $constTableApplication INNER JOIN $constTableApplicationCategory ON $constTableApplication.id=$constTableApplicationCategory.appstream_id where category_id=? ORDER by lastReleaseTimestamp desc LIMIT $limit',
        [categoryId]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int,
            'lastReleaseTimestamp': lastReleaseTimestamp as int
          } in ApplicationEntityList)
        ApplicationEntity(
            id: id,
            name: name,
            summary: summary,
            httpIcon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: lastReleaseTimestamp),
    ];
  }

  Future<List<ApplicationEntity>> findListApplicationEntityByCategoryLimited(
      String categoryId, int limit) async {
    final db = await getDb();
    // Query the table for all the dogs.
    final List<Map<String, Object?>> ApplicationEntityList = await db.rawQuery(
        'SELECT $constTableApplication.id,$constTableApplication.name,$constTableApplication.summary,$constTableApplication.icon,$constTableApplication.lastUpdate,$constTableApplication.lastReleaseTimestamp from $constTableApplication INNER JOIN $constTableApplicationCategory ON $constTableApplication.id=$constTableApplicationCategory.appstream_id where category_id=? ORDER by name asc LIMIT $limit',
        [categoryId]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as String,
            'name': name as String,
            'summary': summary as String,
            'icon': icon as String,
            'lastUpdate': lastUpdate as int,
            'lastReleaseTimestamp': lastReleaseTimestamp as int
          } in ApplicationEntityList)
        ApplicationEntity(
            id: id,
            name: name,
            summary: summary,
            httpIcon: icon,
            categoryIdList: [],
            description: '',
            lastUpdate: lastUpdate,
            metadataObj: {},
            releaseObjList: [],
            urlObj: {},
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: lastReleaseTimestamp),
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

  Future<bool> insertApplicationCategory(
      String appstream_id, String category_id) async {
    final db = await getDb();
    db.insert(
      constTableApplicationCategory,
      {'appstream_id': appstream_id, 'category_id': category_id},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return true;
  }

  Future<bool> insertApplicationCategoryList(
      List<ApplicationCategoryEntity> applicationCategoryList) async {
    final db = await getDb();
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (ApplicationCategoryEntity applicationCategoryLoop
          in applicationCategoryList) {
        try {
          batch.insert(
              constTableApplicationCategory, applicationCategoryLoop.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (exception) {
          throw "some error while insertion";
        }
      }
      await batch.commit(continueOnError: false);
    });

    return true;
  }

  Future<bool> updateApplicationEntity(
      ApplicationEntity ApplicationEntity) async {
    final db = await getDb();
    db.update(
      constTableApplication,
      ApplicationEntity.toMap(),
      where: 'id = ?',
      whereArgs: [ApplicationEntity.id],
    );

    return true;
  }

/*
  Future<void> update(ApplicationEntity dog) async {
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
