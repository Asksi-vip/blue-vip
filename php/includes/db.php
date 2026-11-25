<?php
/**
 * Blue VIP — طبقة البيانات: اتصال SQLite + إنشاء الجداول + بيانات البداية.
 * يستخدمها api/index.php (الـ API العام) و admin/index.php (لوحة الإدارة).
 */

require_once __DIR__ . '/../config.php';

/** فتح اتصال PDO مع SQLite وإنشاء مجلد البيانات. */
function bv_db(): PDO
{
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }
    if (!is_dir(__DIR__ . '/../data')) {
        @mkdir(__DIR__ . '/../data', 0775, true);
    }
    $dsn = 'sqlite:' . __DIR__ . '/../data/bluevip.db';
    $pdo = new PDO($dsn);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->exec('PRAGMA journal_mode = WAL');
    bv_migrate($pdo);
    return $pdo;
}

/** إنشاء الجداول وتعبئة البيانات الافتراضية عند أول تشغيل. */
function bv_migrate(PDO $pdo): void
{
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS categories (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            type  TEXT NOT NULL DEFAULT 'live',  -- live | movies | series
            name  TEXT NOT NULL,
            icon  TEXT NOT NULL DEFAULT '',
            sort  INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS channels (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            name        TEXT NOT NULL,
            logo        TEXT NOT NULL DEFAULT '',
            url         TEXT NOT NULL DEFAULT '',
            backup_url  TEXT NOT NULL DEFAULT '',
            sort        INTEGER NOT NULL DEFAULT 0,
            active      INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS media (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            type        TEXT NOT NULL,             -- movie | series
            category_id INTEGER,
            name        TEXT NOT NULL,
            poster      TEXT NOT NULL DEFAULT '',
            url         TEXT NOT NULL DEFAULT '',  -- للفيلم مباشرة
            year        TEXT NOT NULL DEFAULT '',
            rating      REAL NOT NULL DEFAULT 0,
            description TEXT NOT NULL DEFAULT '',
            sort        INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS episodes (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            media_id INTEGER NOT NULL,
            season   INTEGER NOT NULL DEFAULT 1,
            number   INTEGER NOT NULL DEFAULT 1,
            name     TEXT NOT NULL DEFAULT '',
            url      TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS matches (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            title    TEXT NOT NULL,
            team_a   TEXT NOT NULL DEFAULT '',
            team_b   TEXT NOT NULL DEFAULT '',
            league   TEXT NOT NULL DEFAULT '',
            starts_at TEXT NOT NULL DEFAULT '',  -- 2025-01-01 20:00
            status   TEXT NOT NULL DEFAULT 'upcoming', -- live | upcoming | finished
            sort     INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS match_servers (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            match_id INTEGER NOT NULL,
            name     TEXT NOT NULL,
            url      TEXT NOT NULL,
            quality  TEXT NOT NULL DEFAULT 'HD'
        );
        CREATE TABLE IF NOT EXISTS codes (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            code         TEXT NOT NULL UNIQUE,
            device_id    TEXT NOT NULL DEFAULT '',
            activated_at TEXT NOT NULL DEFAULT '',
            expires_at   TEXT NOT NULL DEFAULT '',
            note         TEXT NOT NULL DEFAULT '',
            days         INTEGER NOT NULL DEFAULT 30
        );
        CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL DEFAULT ''
        );
    ");

    // الإعدادات الافتراضية عند أول تشغيل
    $defaults = array(
        'app_name'        => 'Blue VIP',
        'tagline'         => 'تجربة المشاهدة الترفيهية الفائقة',
        'telegram_url'    => 'https://t.me/bluevip',
        'latest_version'  => '1.0.0',
        'latest_apk_url'  => '',
        'requires_activation' => '0',           // 1 = إجبار تفعيل قبل التشغيل
        'notice'          => '',                // إشعار يظهر في التطبيق
        'admin_user'      => 'admin',
        'admin_pass'      => password_hash('bluevip2025', PASSWORD_DEFAULT),
    );
    $st = $pdo->prepare('INSERT OR IGNORE INTO settings(key, value) VALUES(?, ?)');
    foreach ($defaults as $k => $v) {
        $st->execute(array($k, $v));
    }

    // أقسام البداية (نفس بنية كتالوج IraqMax: أقسام بث مباشر)
    $count = (int) $pdo->query('SELECT COUNT(*) FROM categories')->fetchColumn();
    if ($count === 0) {
        $cats = array(
            array('live', 'القنوات الرياضية', 'sports'),
            array('live', 'باقة beIN SPORTS', 'star'),
            array('live', 'القنوات العراقية', 'flag'),
            array('live', 'القنوات العربية', 'language'),
            array('live', 'قنوات الأخبار', 'news'),
            array('movies', 'أفلام عربية', 'movie'),
            array('movies', 'أفلام أجنبية', 'movie'),
            array('series', 'مسلسلات رمضان', 'tv'),
            array('series', 'مسلسلات أجنبية', 'tv'),
        );
        $st = $pdo->prepare('INSERT INTO categories(type, name, icon, sort) VALUES(?, ?, ?, ?)');
        foreach ($cats as $i => $c) {
            $st->execute(array($c[0], $c[1], $c[2], $i));
        }
    }

    // مباريات تجريبية عند أول تشغيل (حتى لا تظهر الشاشة فارغة)
    $mcount = (int) $pdo->query('SELECT COUNT(*) FROM matches')->fetchColumn();
    if ($mcount === 0) {
        $today = date('Y-m-d');
        $rows = array(
            array('الهندسة × القوة الجوية', 'الهندسة', 'القوة الجوية', 'الدوري العراقي', $today . ' 20:00', 'live'),
            array('الاتحاد × الهلال', 'الاتحاد', 'الهلال', 'دوري أبطال آسيا', $today . ' 22:00', 'upcoming'),
            array('برشلونة × ريال مدريد', 'برشلونة', 'ريال مدريد', 'الليجا', $today . ' 18:00', 'finished'),
        );
        $st = $pdo->prepare('INSERT INTO matches(title, team_a, team_b, league, starts_at, status) VALUES(?,?,?,?,?,?)');
        foreach ($rows as $i => $r) {
            $st->execute(array_merge($r, array($i)));
        }
        $mid = (int) $pdo->lastInsertId();
        $st2 = $pdo->prepare('INSERT INTO match_servers(match_id, name, url, quality) VALUES(?,?,?,?)');
        $st2->execute(array($mid, 'سيرفر 1 (HD)', '', 'HD'));
    }
}

/** قراءة إعداد واحد. */
function bv_setting(string $key, string $default = ''): string
{
    $st = bv_db()->prepare('SELECT value FROM settings WHERE key = ?');
    $st->execute(array($key));
    $v = $st->fetchColumn();
    return $v === false ? $default : (string) $v;
}

/** كتابة إعداد. */
function bv_set_setting(string $key, string $value): void
{
    bv_db()->prepare('INSERT INTO settings(key, value) VALUES(?, ?)
                      ON CONFLICT(key) DO UPDATE SET value = excluded.value')
        ->execute(array($key, $value));
}

/** إخراج JSON مع ترويسات CORS (يستهلكه التطبيق مباشرة). */
function bv_json(array $data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/** تنظيف مدخل نصي. */
function bv_str(string $key, int $max = 500): string
{
    $v = isset($_REQUEST[$key]) ? trim((string) $_REQUEST[$key]) : '';
    return mb_substr($v, 0, $max);
}

/** تحويل صريح لعدد صحيح. */
function bv_int(string $key, int $default = 0): int
{
    return isset($_REQUEST[$key]) ? (int) $_REQUEST[$key] : $default;
}

/** بناء رابط الـ API العام للعرض في اللوحة (admin/ → api/). */
function bv_api_url(string $action): string
{
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
    $base = isset($_SERVER['SCRIPT_NAME']) ? dirname(dirname($_SERVER['SCRIPT_NAME'])) : '';
    return $scheme . '://' . $host . rtrim(str_replace('\\', '/', $base), '/')
        . '/api/index.php?action=' . $action;
}

/** توليد كود VIP قابل للقراءة مثل BV-XXXX-XXXX. */
function bv_generate_code(): string
{
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    $part = function () use ($alphabet) {
        $s = '';
        for ($i = 0; $i < 4; $i++) {
            $s .= $alphabet[random_int(0, strlen($alphabet) - 1)];
        }
        return $s;
    };
    return 'BV-' . $part() . '-' . $part();
}
