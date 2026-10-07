// Renders the Play Store screenshots (spec 2.2: 8 × 1080×1920, captioned
// top band), the feature graphic (1024×500) and the 512 px icon into
// store/, from the real app with realistic demo data. Dev tool:
//
//   flutter test tool/store/render_store_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaata_digital/app.dart';
import 'package:khaata_digital/core/dates/budget_cycle.dart';
import 'package:khaata_digital/core/db/app_database.dart';
import 'package:khaata_digital/core/di/injection.dart';
import 'package:khaata_digital/core/money/currency.dart';
import 'package:khaata_digital/core/money/money.dart';
import 'package:khaata_digital/core/router/routes.dart';
import 'package:khaata_digital/core/widgets/glass_nav_bar.dart';
import 'package:khaata_digital/features/accounts/domain/account_presets.dart';
import 'package:khaata_digital/features/backup/data/backup_service.dart';
import 'package:khaata_digital/features/backup/domain/backup.dart';
import 'package:khaata_digital/features/backup/domain/cloud_backup_store.dart';
import 'package:khaata_digital/features/settings/domain/setting_key.dart';
import 'package:khaata_digital/features/settings/domain/settings_repository.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/preference_cubits.dart';
import 'package:khaata_digital/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:khaata_digital/features/transactions/domain/ledger_entry.dart';
import 'package:khaata_digital/features/transactions/domain/transaction_type.dart';
import 'package:khaata_digital/features/transactions/domain/transactions_repository.dart';

import '../../test/helpers/fake_cloud.dart';
import '../../test/helpers/test_app.dart';

Future<void> _font(String family, String path) async {
  final l = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await l.load();
}

const _green1 = Color(0xFF16A363);
const _green2 = Color(0xFF0B6B40);

final _shot = GlobalKey();

Future<ui.Image> _image(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

Future<void> _write(
  String path,
  ui.PictureRecorder rec,
  double w,
  double h,
) async {
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    // Phosphor's icon fonts, wherever this machine keeps packages.
    final config =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, dynamic>;
    final phosphor = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['name'] == 'phosphor_flutter');
    final root = Uri.parse(
      '${Directory.current.uri}.dart_tool/',
    ).resolve(phosphor['rootUri'] as String);
    final fonts = '${root.toFilePath()}/lib/fonts';
    await _font('Manrope', 'assets/fonts/Manrope-Variable.ttf');
    await _font(
      'packages/phosphor_flutter/PhosphorRegular',
      '$fonts/Phosphor.ttf',
    );
    await _font(
      'packages/phosphor_flutter/PhosphorFill',
      '$fonts/Phosphor-Fill.ttf',
    );
    await _font(
      'packages/phosphor_flutter/PhosphorBold',
      '$fonts/Phosphor-Bold.ttf',
    );
  });

  Future<void> seed(AppDatabase db) async {
    final now = DateTime.now();
    final tx = getIt<TransactionsRepository>();
    final cash = (await db.accountsDao.balances()).single.account.id;
    await db.accountsDao.edit(
      cash,
      const AccountsCompanion(openingBalanceMinor: Value(1200000)),
    );
    Future<String> acc(String presetKey, int opening) {
      final p = AccountPresets.byKey(presetKey)!;
      return db.accountsDao.create(
        name: p.name,
        type: p.type,
        currencyCode: 'PKR',
        openingBalanceMinor: opening * 100,
        icon: p.key,
        color: p.color,
      );
    }

    final meezan = await acc('meezan', 85000);
    final easypaisa = await acc('easypaisa', 25000);
    await acc('jazzcash', 2350);
    await acc('hbl', 40000);
    final cats = {
      for (final c in await db.categoriesDao.active()) c.name: c.id,
    };
    final cycle = const BudgetCycle.calendar();
    final start = cycle.rangeFor(now).start;
    Future<void> add(
      TransactionType type,
      int rupees,
      String account,
      String? category,
      int dayOffset,
      String note, {
      String? person,
    }) => tx.save(
      EntryDraft(
        type: type,
        amount: Money.major(rupees, Currency.pkr),
        accountId: account,
        categoryId: category == null ? null : cats[category],
        personId: person,
        occurredAt: start
            .add(Duration(days: dayOffset, hours: 11 + dayOffset % 7))
            .toUtc(),
        note: note,
      ),
    );

    await add(TransactionType.income, 185000, meezan, 'Salary', 0, 'Salary');
    final spend = [
      ('Grocery', 6450, 'Imtiaz — monthly ration'),
      ('Food & Drink', 1250, 'Biryani with Ali'),
      ('Fuel & Maintenance', 4800, 'Petrol'),
      ('Bills & Utilities', 7350, 'K-Electric bill'),
      ('Mobile', 1200, 'Jazz package'),
      ('Shopping', 5600, 'Eid kurta'),
      ('Food & Drink', 780, 'Chai & paratha'),
      ('Education', 12000, 'School fee'),
      ('Medical', 2150, 'Pharmacy'),
      ('Grocery', 2300, 'Fruit & veg'),
    ];
    for (var i = 0; i < spend.length; i++) {
      final (cat, amount, note) = spend[i];
      if (start.add(Duration(days: i + 1)).isAfter(now)) break;
      await add(
        TransactionType.expense,
        amount,
        i.isEven ? meezan : easypaisa,
        cat,
        i + 1,
        note,
      );
    }
    final ahmed = await db.peopleDao.create(name: 'Ahmed Bhai');
    final sara = await db.peopleDao.create(name: 'Sara');
    await add(
      TransactionType.expense,
      5000,
      cash,
      null,
      1,
      'Loan',
      person: ahmed,
    );
    await add(
      TransactionType.income,
      1200,
      cash,
      null,
      2,
      'Lunch money',
      person: sara,
    );
    final id = cycle.idFor(now);
    await db.budgetsDao.setBudget(id, 8000000);
    for (final (cat, limit) in [
      ('Grocery', 12000),
      ('Food & Drink', 6000),
      ('Fuel & Maintenance', 8000),
      ('Shopping', 5000),
    ]) {
      await db.budgetsDao.setBudget(id, limit * 100, categoryId: cats[cat]);
    }
    // A Drive backup, so the backup screen shows its status.
    (getIt<CloudBackupStore>() as FakeCloudStore).account = 'you@gmail.com';
    await getIt<SettingsRepository>().write(
      SettingKey.driveAccount,
      'you@gmail.com',
    );
    await getIt<SettingsRepository>().write(SettingKey.autoBackup, 'true');
    // Store screenshots show the numbers (the app starts with them hidden).
    await getIt<HideBalanceCubit>().set(false);
    final backups = getIt<BackupService>();
    await backups.record(await backups.create(), BackupDestination.drive);
  }

  Future<ui.Image> capture(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 600));
    final boundary =
        _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (await t.runAsync(() => boundary.toImage(pixelRatio: 3)))!;
  }

  Future<void> compose(
    WidgetTester t,
    String file,
    String caption,
    ui.Image screen,
  ) async {
    await t.runAsync(() async {
      const w = 1080.0, h = 1920.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      const r = Rect.fromLTWH(0, 0, w, h);
      c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [
            _green1,
            _green2,
          ]),
      );
      final p = TextPainter(
        text: TextSpan(
          text: caption,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 68,
            height: 1.15,
            fontVariations: [FontVariation('wght', 800)],
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: w - 160);
      p.paint(c, Offset((w - p.width) / 2, 120));
      // The phone.
      const phoneW = 820.0;
      final phoneH = phoneW * screen.height / screen.width;
      final phone = Rect.fromLTWH((w - phoneW) / 2, 420, phoneW, phoneH);
      final rr = RRect.fromRectAndRadius(phone, const Radius.circular(56));
      c.drawRRect(
        rr.shift(const Offset(0, 24)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
      c.save();
      c.clipRRect(rr);
      c.drawImageRect(
        screen,
        Rect.fromLTWH(0, 0, screen.width.toDouble(), screen.height.toDouble()),
        phone,
        Paint()..filterQuality = FilterQuality.high,
      );
      c.restore();
      c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = const Color(0xFF0A1F16),
      );
      final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        'store/screenshots/$file.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<AppDatabase> boot(WidgetTester t, {bool dark = false}) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 72, bottom: 48);
    addTearDown(t.view.reset);
    late AppDatabase db;
    await t.runAsync(() async {
      db = await setUpTestApp();
      await seed(db);
      if (dark) await getIt<ThemeCubit>().set(ThemeMode.dark);
    });
    await t.pumpWidget(RepaintBoundary(key: _shot, child: const KharchaApp()));
    await t.pumpAndSettle();
    return db;
  }

  Future<void> go(WidgetTester t, String route) async {
    unawaited(t.element(find.byType(GlassNavBar)).push(route));
    await t.pumpAndSettle();
  }

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find.descendant(of: find.byType(GlassNavBar), matching: find.text(label)),
    );
    await t.pumpAndSettle();
  }

  testWidgets('screenshots', (t) async {
    await boot(t);
    await compose(
      t,
      '1_home',
      'Apka poora kharcha, aik nazar mein',
      await capture(t),
    );

    await t.tap(find.bySemanticsLabel('Add'));
    await t.pumpAndSettle();
    for (final d in [1, 2, 5, 0]) {
      await t.tap(find.byKey(Key('key-d$d')));
      await t.pump();
    }
    await t.pumpAndSettle();
    await compose(t, '2_add', 'Add an expense in 3 seconds', await capture(t));
    await t.tap(find.byKey(const Key('closeEditor')));
    await t.pumpAndSettle();

    await go(t, Routes.budgets);
    await compose(
      t,
      '3_budgets',
      'Set budgets. Stay on track.',
      await capture(t),
    );
    t.element(find.byType(Scaffold).last).pop();
    await t.pumpAndSettle();

    await tab(t, 'Reports');
    await compose(
      t,
      '4_reports',
      'Any date range. Full history.',
      await capture(t),
    );
    await tab(t, 'Home');

    await go(t, Routes.people);
    await compose(
      t,
      '5_people',
      'Udhaar ka hisab, both ways',
      await capture(t),
    );
    t.element(find.byType(Scaffold).last).pop();
    await t.pumpAndSettle();

    await go(t, Routes.backup);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pumpAndSettle();
    await compose(
      t,
      '6_backup',
      'One-tap backup to YOUR Google Drive',
      await capture(t),
    );
    t.element(find.byType(Scaffold).last).pop();
    await t.pumpAndSettle();

    await go(t, Routes.accounts);
    await compose(
      t,
      '7_accounts',
      'All your accounts in one place',
      await capture(t),
    );
  });

  testWidgets('dark mode, feature graphic and Play icon', (t) async {
    await boot(t, dark: true);
    await compose(t, '8_dark', 'Dark mode included', await capture(t));

    await t.runAsync(() => getIt<ThemeCubit>().set(ThemeMode.light));
    await t.pumpAndSettle();
    final home = await capture(t);
    await t.runAsync(() async {
      // Feature graphic (1024×500): message left, the app right.
      const w = 1024.0, h = 500.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      const r = Rect.fromLTWH(0, 0, w, h);
      c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [
            _green1,
            _green2,
          ]),
      );
      final mark = await _image('assets/splash/mark.png');
      c.drawImageRect(
        mark,
        Rect.fromLTWH(0, 0, mark.width.toDouble(), mark.height.toDouble()),
        const Rect.fromLTWH(64, 88, 84, 84),
        Paint()..filterQuality = FilterQuality.high,
      );
      void text(String s, double y, double size, int weight, double alpha) {
        TextPainter(
            text: TextSpan(
              text: s,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: size,
                height: 1.1,
                fontVariations: [FontVariation('wght', weight.toDouble())],
                color: Colors.white.withValues(alpha: alpha),
                letterSpacing: -0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )
          ..layout(maxWidth: 560)
          ..paint(c, Offset(64, y));
      }

      text('Kharcha', 196, 64, 800, 1);
      text('Pakistan ka budget app', 276, 38, 700, 0.95);
      text('Offline · Free · No login', 336, 28, 600, 0.8);
      const phoneW = 250.0;
      final phoneH = phoneW * home.height / home.width;
      final phone = Rect.fromLTWH(w - phoneW - 80, 56, phoneW, phoneH);
      final rr = RRect.fromRectAndRadius(phone, const Radius.circular(30));
      c.drawRRect(
        rr.shift(const Offset(0, 14)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      c.save();
      c.clipRRect(rr);
      c.drawImageRect(
        home,
        Rect.fromLTWH(0, 0, home.width.toDouble(), home.height.toDouble()),
        phone,
        Paint()..filterQuality = FilterQuality.high,
      );
      c.restore();
      c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0xFF0A1F16),
      );
      await _write('store/feature_graphic.png', rec, w, h);

      // Play icon (512, full bleed — Play applies its own mask).
      final iconRec = ui.PictureRecorder();
      final icon = await _image('assets/splash/icon_ios.png');
      Canvas(iconRec).drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        const Rect.fromLTWH(0, 0, 512, 512),
        Paint()..filterQuality = FilterQuality.high,
      );
      await _write('store/icon_512.png', iconRec, 512, 512);
    });
  });
}
