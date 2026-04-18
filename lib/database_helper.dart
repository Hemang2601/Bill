import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shree_shakti.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure, // CRITICAL: Enables Foreign Keys for Cascade Delete
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // --- ENSURE CASCADE DELETES WORK ---
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Managers Table
    await db.execute('''
      CREATE TABLE managers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // 2. Invoices Table (Header)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billNumber TEXT NOT NULL,
        customerName TEXT,
        phoneNumber TEXT,
        date TEXT,
        totalAmount REAL,
        pdfPath TEXT 
      )
    ''');

    // 3. Invoice Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER,
        itemName TEXT,
        qty REAL,
        price REAL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Seed Managers
    await db.insert('managers', {'username': 'hiren', 'password': '3112'});
    await db.insert('managers', {'username': 'suresh', 'password': '1975'});
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, billNumber TEXT, customerName TEXT, phoneNumber TEXT, date TEXT, totalAmount REAL)');
      await db.execute('CREATE TABLE IF NOT EXISTS invoice_items (id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceId INTEGER, itemName TEXT, qty REAL, price REAL, FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE)');
    }

    if (oldVersion < 3) {
      // Logic to add pdfPath column to existing DB
      var tableInfo = await db.rawQuery('PRAGMA table_info(invoices)');
      bool columnExists = tableInfo.any((column) => column['name'] == 'pdfPath');
      if (!columnExists) {
        await db.execute('ALTER TABLE invoices ADD COLUMN pdfPath TEXT');
      }
    }
  }

  // --- INVOICE OPERATIONS ---

  Future<int> saveCompleteInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      int invoiceId = await txn.insert('invoices', invoice);
      for (var item in items) {
        await txn.insert('invoice_items', {
          'invoiceId': invoiceId,
          'itemName': item['itemName'],
          'qty': item['qty'],
          'price': item['price'],
        });
      }
      return invoiceId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await instance.database;
    return await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
  }

  /// Deletes an invoice.
  /// Because of ON DELETE CASCADE, this also deletes all items in 'invoice_items'.
  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- EDIT / UPDATE INVOICE OPERATIONS ---

  /// Updates an existing invoice and its items safely using a transaction
  Future<void> updateCompleteInvoice({required Map<String, dynamic> invoiceData, required List<Map<String, dynamic>> items}) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Update the main invoice table
      await txn.update(
          'invoices',
          invoiceData,
          where: 'id = ?',
          whereArgs: [invoiceData['id']]
      );

      // 2. Delete old items linked to this invoice
      await txn.delete(
          'invoice_items',
          where: 'invoiceId = ?',
          whereArgs: [invoiceData['id']]
      );

      // 3. Insert the updated items
      for (var item in items) {
        await txn.insert('invoice_items', item);
      }
    });
  }

  // --- MANAGER OPERATIONS ---

  Future<bool> validateLogin(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'managers',
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim(), password.trim()],
    );
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllManagers() async {
    final db = await instance.database;
    return await db.query('managers');
  }

  Future<int> addManager(String username, String password) async {
    final db = await instance.database;
    return await db.insert('managers', {'username': username, 'password': password});
  }

  Future<int> updatePassword(String username, String newPassword) async {
    final db = await instance.database;
    return await db.update('managers', {'password': newPassword}, where: 'username = ?', whereArgs: [username]);
  }

  Future<int> deleteManager(int id) async {
    final db = await instance.database;
    return await db.delete('managers', where: 'id = ?', whereArgs: [id]);
  }

  // --- STATISTICS METHODS ---
  Future<Map<String, dynamic>> getInvoiceStats() async {
    final db = await instance.database;
    var stats = await db.rawQuery('SELECT COUNT(*) as totalCount, SUM(totalAmount) as totalRev FROM invoices');
    return {
      'totalCount': stats.first['totalCount'] ?? 0,
      'totalRev': stats.first['totalRev'] ?? 0.0,
    };
  }

  // =========================================================
  // --- FILTERING METHODS FOR HISTORY PAGE ------------------
  // =========================================================

  /// A robust date parser to handle both YYYY-MM-DD and DD/MM/YYYY formats properly
  static DateTime? parseDateRobust(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Try standard ISO format first
      return DateTime.parse(dateStr.trim());
    } catch (_) {
      try {
        final cleanDate = dateStr.trim().split(' ')[0];
        final parts = cleanDate.contains('/') ? cleanDate.split('/') : cleanDate.split('-');
        if (parts.length >= 3) {
          // Handle DD/MM/YYYY or YYYY/MM/DD
          if (parts[0].length == 4) {
            return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Fetches invoices from DB based on Search Query and Date Range boundaries
  Future<List<Map<String, dynamic>>> getFilteredInvoices({
    String searchQuery = "",
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;
    List<Map<String, dynamic>> rawResults;

    // 1. Ask SQLite to filter by Search Text AND sort by ID DESC (Newest first)
    // Sorting by ID DESC is a reliable way to get the latest entries in SQLite
    if (searchQuery.isNotEmpty) {
      rawResults = await db.query(
        'invoices',
        where: 'customerName LIKE ? OR billNumber LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'id DESC',
      );
    } else {
      rawResults = await db.query(
        'invoices',
        orderBy: 'id DESC',
      );
    }

    // Convert to modifiable list
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(rawResults);

    // 2. Filter by Dates in Dart (only if dates are provided)
    if (startDate != null && endDate != null) {
      results = results.where((inv) {
        final dateStr = inv['date']?.toString() ?? "";
        DateTime? invDate = parseDateRobust(dateStr);
        if (invDate == null) return false;

        // Strip time for clean day-to-day comparison
        DateTime cleanInv = DateTime(invDate.year, invDate.month, invDate.day);
        DateTime cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
        DateTime cleanEnd = DateTime(endDate.year, endDate.month, endDate.day);

        return !cleanInv.isBefore(cleanStart) && !cleanInv.isAfter(cleanEnd);
      }).toList();
    }

    // 3. Final Sort (Safety net to ensure Date-based descending order)
    results.sort((a, b) {
      DateTime dateA = parseDateRobust(a['date']?.toString() ?? "") ?? DateTime(1970);
      DateTime dateB = parseDateRobust(b['date']?.toString() ?? "") ?? DateTime(1970);

      // Compare dates; if dates are equal, compare IDs to keep newest on top
      int dateCompare = dateB.compareTo(dateA);
      if (dateCompare == 0) {
        return (b['id'] as int).compareTo(a['id'] as int);
      }
      return dateCompare;
    });

    return results;
  }
}