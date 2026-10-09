import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'receipt_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        merchant_name TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT NOT NULL,
        receipt_image_path TEXT,
        raw_ocr_text TEXT,
        subtotal INTEGER,
        tax_amount INTEGER,
        discount_amount INTEGER,
        receipt_number TEXT,
        source_type TEXT NOT NULL DEFAULT '${AppConstants.sourceReceiptOcr}',
        payment_status TEXT NOT NULL DEFAULT '${AppConstants.statusUserConfirmed}',
        verification_status TEXT NOT NULL DEFAULT '${AppConstants.statusUserConfirmed}',
        transaction_reference TEXT,
        bank_name TEXT,
        sender_name TEXT,
        sender_account TEXT,
        recipient_name TEXT,
        recipient_account TEXT,
        transfer_description TEXT,
        transaction_datetime TEXT,
        currency TEXT NOT NULL DEFAULT 'VND',
        original_qr_payload TEXT,
        ocr_confidence TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Indexes for date, category, and source_type
    await db.execute(
      'CREATE INDEX idx_expenses_date ON expenses(expense_date DESC);',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category);',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_source ON expenses(source_type);',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate v1 schema to v2 by safely adding missing columns
      final columns = [
        "ALTER TABLE expenses ADD COLUMN source_type TEXT NOT NULL DEFAULT '${AppConstants.sourceReceiptOcr}';",
        "ALTER TABLE expenses ADD COLUMN payment_status TEXT NOT NULL DEFAULT '${AppConstants.statusUserConfirmed}';",
        "ALTER TABLE expenses ADD COLUMN verification_status TEXT NOT NULL DEFAULT '${AppConstants.statusUserConfirmed}';",
        "ALTER TABLE expenses ADD COLUMN transaction_reference TEXT;",
        "ALTER TABLE expenses ADD COLUMN bank_name TEXT;",
        "ALTER TABLE expenses ADD COLUMN sender_name TEXT;",
        "ALTER TABLE expenses ADD COLUMN sender_account TEXT;",
        "ALTER TABLE expenses ADD COLUMN recipient_name TEXT;",
        "ALTER TABLE expenses ADD COLUMN recipient_account TEXT;",
        "ALTER TABLE expenses ADD COLUMN transfer_description TEXT;",
        "ALTER TABLE expenses ADD COLUMN transaction_datetime TEXT;",
        "ALTER TABLE expenses ADD COLUMN currency TEXT NOT NULL DEFAULT 'VND';",
        "ALTER TABLE expenses ADD COLUMN original_qr_payload TEXT;",
        "ALTER TABLE expenses ADD COLUMN ocr_confidence TEXT;",
      ];

      for (final sql in columns) {
        try {
          await db.execute(sql);
        } catch (_) {
          // Ignore if column already exists
        }
      }

      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_source ON expenses(source_type);',
        );
      } catch (_) {}
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
