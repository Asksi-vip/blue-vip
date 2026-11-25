<?php
/**
 * Blue VIP — لوحة الإدارة (PHP + SQLite).
 *
 * أول تشغيل: admin / bluevip2025 (غيّرها من صفحة الإعدادات فوراً).
 * الصفحات: dashboard, categories, channels, media, matches, codes, settings.
 * كل العمليات POST مع إعادة توجيه (PRG) وحماية CSRF بجلسة.
 */

require_once __DIR__ . '/../includes/db.php';

session_name('bluevip_admin');
session_start();

// ---------- تسجيل الدخول والخروج ----------
if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: ?');
    exit;
}

$logged = !empty($_SESSION['bv_admin']);

if (!$logged && isset($_POST['login_user'], $_POST['login_pass'])) {
    if (hash_equals(bv_setting('admin_user'), $_POST['login_user'])
        && password_verify($_POST['login_pass'], bv_setting('admin_pass'))) {
        $_SESSION['bv_admin'] = true;
        $_SESSION['bv_csrf'] = bin2hex(random_bytes(16));
        header('Location: ?');
        exit;
    }
    $loginError = 'اسم المستخدم أو كلمة المرور غير صحيحة';
}

function bv_csrf(): string
{
    return isset($_SESSION['bv_csrf']) ? $_SESSION['bv_csrf'] : '';
}

function bv_check_csrf(): void
{
    if (!isset($_POST['csrf']) || !hash_equals(bv_csrf(), (string) $_POST['csrf'])) {
        http_response_code(403);
        exit('CSRF token mismatch');
    }
}

// ---------- العمليات (بعد التحقق من الدخول) ----------
if ($logged && $_SERVER['REQUEST_METHOD'] === 'POST') {
    bv_check_csrf();
    $do = isset($_POST['do']) ? (string) $_POST['do'] : '';
    $pdo = bv_db();

    switch ($do) {
        // الأقسام
        case 'cat_add':
            $pdo->prepare('INSERT INTO categories(type, name, icon, sort) VALUES(?,?,?,?)')
                ->execute(array(bv_str('type', 10), bv_str('name', 80), bv_str('icon', 40), bv_int('sort')));
            break;
        case 'cat_edit':
            $pdo->prepare('UPDATE categories SET name = ?, icon = ?, sort = ? WHERE id = ?')
                ->execute(array(bv_str('name', 80), bv_str('icon', 40), bv_int('sort'), bv_int('id')));
            break;
        case 'cat_del':
            $type = bv_str('type', 10);
            $pdo->prepare('DELETE FROM categories WHERE id = ?')->execute(array(bv_int('id')));
            if ($type === 'live') {
                $pdo->prepare('DELETE FROM channels WHERE category_id = ?')->execute(array(bv_int('id')));
            }
            if ($type === 'movies' || $type === 'series') {
                $pdo->prepare('UPDATE media SET category_id = NULL WHERE category_id = ?')->execute(array(bv_int('id')));
            }
            break;

        // القنوات
        case 'ch_add':
            $pdo->prepare('INSERT INTO channels(category_id, name, logo, url, backup_url, sort) VALUES(?,?,?,?,?,?)')
                ->execute(array(bv_int('category_id'), bv_str('name', 100), bv_str('logo', 400),
                                bv_str('url', 600), bv_str('backup_url', 600), bv_int('sort')));
            break;
        case 'ch_edit':
            $pdo->prepare('UPDATE channels SET name = ?, logo = ?, url = ?, backup_url = ?, sort = ?, active = ? WHERE id = ?')
                ->execute(array(bv_str('name', 100), bv_str('logo', 400), bv_str('url', 600),
                                bv_str('backup_url', 600), bv_int('sort'), bv_int('active') ? 1 : 0, bv_int('id')));
            break;
        case 'ch_del':
            $pdo->prepare('DELETE FROM channels WHERE id = ?')->execute(array(bv_int('id')));
            break;

        // الأفلام والمسلسلات
        case 'media_add':
            $pdo->prepare('INSERT INTO media(type, category_id, name, poster, url, year, rating, description, sort) VALUES(?,?,?,?,?,?,?,?,?)')
                ->execute(array(bv_str('type', 10), bv_int('category_id'), bv_str('name', 150),
                                bv_str('poster', 400), bv_str('url', 600), bv_str('year', 10),
                                bv_int('rating'), bv_str('description', 1000), bv_int('sort')));
            break;
        case 'media_edit':
            $pdo->prepare('UPDATE media SET name = ?, poster = ?, url = ?, year = ?, rating = ?, description = ?, sort = ?, category_id = ? WHERE id = ?')
                ->execute(array(bv_str('name', 150), bv_str('poster', 400), bv_str('url', 600),
                                bv_str('year', 10), bv_int('rating'), bv_str('description', 1000),
                                bv_int('sort'), bv_int('category_id'), bv_int('id')));
            break;
        case 'media_del':
            $pdo->prepare('DELETE FROM episodes WHERE media_id = ?')->execute(array(bv_int('id')));
            $pdo->prepare('DELETE FROM media WHERE id = ?')->execute(array(bv_int('id')));
            break;
        case 'ep_add':
            $pdo->prepare('INSERT INTO episodes(media_id, season, number, name, url) VALUES(?,?,?,?,?)')
                ->execute(array(bv_int('media_id'), max(1, bv_int('season')), max(1, bv_int('number')),
                                bv_str('name', 120), bv_str('url', 600)));
            break;
        case 'ep_del':
            $pdo->prepare('DELETE FROM episodes WHERE id = ?')->execute(array(bv_int('id')));
            break;

        // المباريات
        case 'match_add':
            $pdo->prepare('INSERT INTO matches(title, team_a, team_b, league, starts_at, status, sort) VALUES(?,?,?,?,?,?,?)')
                ->execute(array(bv_str('title', 150), bv_str('team_a', 80), bv_str('team_b', 80),
                                bv_str('league', 80), bv_str('starts_at', 20), bv_str('status', 10), bv_int('sort')));
            break;
        case 'match_edit':
            $pdo->prepare('UPDATE matches SET title = ?, team_a = ?, team_b = ?, league = ?, starts_at = ?, status = ?, sort = ? WHERE id = ?')
                ->execute(array(bv_str('title', 150), bv_str('team_a', 80), bv_str('team_b', 80),
                                bv_str('league', 80), bv_str('starts_at', 20), bv_str('status', 10),
                                bv_int('sort'), bv_int('id')));
            break;
        case 'match_del':
            $pdo->prepare('DELETE FROM match_servers WHERE match_id = ?')->execute(array(bv_int('id')));
            $pdo->prepare('DELETE FROM matches WHERE id = ?')->execute(array(bv_int('id')));
            break;
        case 'srv_add':
            $pdo->prepare('INSERT INTO match_servers(match_id, name, url, quality) VALUES(?,?,?,?)')
                ->execute(array(bv_int('match_id'), bv_str('name', 80), bv_str('url', 600), bv_str('quality', 10)));
            break;
        case 'srv_del':
            $pdo->prepare('DELETE FROM match_servers WHERE id = ?')->execute(array(bv_int('id')));
            break;

        // أكواد VIP
        case 'code_gen':
            $days = max(1, bv_int('days', 30));
            $count = min(50, max(1, bv_int('count', 1)));
            $st = $pdo->prepare('INSERT OR IGNORE INTO codes(code, days, note) VALUES(?,?,?)');
            for ($i = 0; $i < $count; $i++) {
                $st->execute(array(bv_generate_code(), $days, bv_str('note', 120)));
            }
            break;
        case 'code_del':
            $pdo->prepare('DELETE FROM codes WHERE id = ?')->execute(array(bv_int('id')));
            break;
        case 'code_reset':
            // إعادة تعيين: فك الجهاز حتى يُفعّل من جديد
            $pdo->prepare("UPDATE codes SET device_id = '', activated_at = '', expires_at = '' WHERE id = ?")
                ->execute(array(bv_int('id')));
            break;

        // الإعدادات
        case 'settings_save':
            bv_set_setting('app_name', bv_str('app_name', 60));
            bv_set_setting('tagline', bv_str('tagline', 160));
            bv_set_setting('telegram_url', bv_str('telegram_url', 200));
            bv_set_setting('latest_version', bv_str('latest_version', 20));
            bv_set_setting('latest_apk_url', bv_str('latest_apk_url', 400));
            bv_set_setting('requires_activation', bv_int('requires_activation') ? '1' : '0');
            bv_set_setting('notice', bv_str('notice', 300));
            break;
        case 'admin_save':
            $u = bv_str('admin_user', 40);
            $p = (string) (isset($_POST['admin_pass']) ? $_POST['admin_pass'] : '');
            if ($u !== '') {
                bv_set_setting('admin_user', $u);
            }
            if (strlen($p) >= 6) {
                bv_set_setting('admin_pass', password_hash($p, PASSWORD_DEFAULT));
            }
            break;
    }

    header('Location: ?page=' . urlencode(bv_str('page', 20)));
    exit;
}

// ---------- اختيار الصفحة ----------
$page = isset($_GET['page']) ? (string) $_GET['page'] : 'dashboard';
$allowed = array('dashboard', 'categories', 'channels', 'media', 'matches', 'codes', 'settings');
if (!in_array($page, $allowed, true)) {
    $page = 'dashboard';
}

// ---------- إحصائيات لوحة القيادة ----------
$stats = array(
    'channels' => (int) bv_db()->query('SELECT COUNT(*) FROM channels')->fetchColumn(),
    'cats'     => (int) bv_db()->query('SELECT COUNT(*) FROM categories')->fetchColumn(),
    'movies'   => (int) bv_db()->query("SELECT COUNT(*) FROM media WHERE type = 'movie'")->fetchColumn(),
    'series'   => (int) bv_db()->query("SELECT COUNT(*) FROM media WHERE type = 'series'")->fetchColumn(),
    'matches'  => (int) bv_db()->query('SELECT COUNT(*) FROM matches')->fetchColumn(),
    'live'     => (int) bv_db()->query("SELECT COUNT(*) FROM matches WHERE status = 'live'")->fetchColumn(),
    'codes'    => (int) bv_db()->query('SELECT COUNT(*) FROM codes')->fetchColumn(),
    'active'   => (int) bv_db()->query("SELECT COUNT(*) FROM codes WHERE device_id != '' AND (expires_at = '' OR expires_at >= datetime('now','localtime'))")->fetchColumn(),
);
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Blue VIP — لوحة الإدارة</title>
<style>
:root{
  --bg:#0b0c10; --surface:#13151f; --card:#181b26; --border:#262a36;
  --blue:#3b82f6; --blue-light:#60a5fa; --red:#dc2626; --green:#10b981;
  --text:#f8fafc; --muted:#94a3b8;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',Tahoma,Arial,sans-serif;min-height:100vh}
a{color:var(--blue-light);text-decoration:none}
.container{max-width:1100px;margin:0 auto;padding:20px}
/* شريط علوي */
.topbar{display:flex;align-items:center;gap:14px;padding:14px 20px;background:var(--surface);border-bottom:1px solid var(--border);flex-wrap:wrap}
.topbar .brand{font-size:18px;font-weight:800;color:var(--blue-light);letter-spacing:.5px}
.topbar .badge{font-size:11px;background:rgba(59,130,246,.15);border:1px solid rgba(59,130,246,.4);color:var(--blue-light);border-radius:6px;padding:3px 10px}
.topbar .spacer{flex:1}
/* تنقل */
.nav{display:flex;gap:6px;flex-wrap:wrap;padding:10px 20px;background:var(--surface);border-bottom:1px solid var(--border)}
.nav a{padding:8px 14px;border-radius:8px;color:var(--muted);font-size:13.5px;font-weight:600}
.nav a.active{background:rgba(59,130,246,.15);color:var(--blue-light);border:1px solid rgba(59,130,246,.4)}
.nav a:hover{color:var(--text)}
/* بطاقات إحصائيات */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:20px 0}
.stat{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:16px}
.stat .n{font-size:26px;font-weight:800;color:var(--blue-light)}
.stat .t{font-size:12.5px;color:var(--muted);margin-top:4px}
/* جدول */
table{width:100%;border-collapse:collapse;background:var(--card);border:1px solid var(--border);border-radius:12px;overflow:hidden;margin-top:14px}
th{background:var(--surface);text-align:right;font-size:12.5px;color:var(--muted);padding:10px 12px;font-weight:700}
td{padding:10px 12px;border-top:1px solid var(--border);font-size:13.5px;vertical-align:middle}
tr:hover td{background:rgba(59,130,246,.05)}
.table-wrap{overflow-x:auto;-webkit-overflow-scrolling:touch}
/* نماذج */
input,select,textarea{background:#0e1017;border:1px solid var(--border);border-radius:8px;color:var(--text);padding:9px 12px;font-size:13.5px;font-family:inherit;width:100%}
input:focus,select:focus,textarea:focus{outline:none;border-color:var(--blue)}
label{display:block;font-size:12px;color:var(--muted);margin:10px 0 5px}
.btn{display:inline-block;background:var(--blue);color:#fff;border:none;border-radius:8px;padding:9px 16px;font-size:13.5px;font-weight:700;cursor:pointer;font-family:inherit}
.btn:hover{background:var(--blue-light)}
.btn.secondary{background:transparent;border:1px solid var(--border);color:var(--muted)}
.btn.danger{background:transparent;border:1px solid rgba(220,38,38,.5);color:var(--red)}
.btn.small{padding:5px 10px;font-size:12px;border-radius:6px}
.pill{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:700}
.pill.live{background:rgba(220,38,38,.15);color:var(--red);border:1px solid rgba(220,38,38,.4)}
.pill.upcoming{background:rgba(59,130,246,.15);color:var(--blue-light);border:1px solid rgba(59,130,246,.4)}
.pill.finished{background:rgba(148,163,184,.15);color:var(--muted);border:1px solid var(--border)}
.pill.ok{background:rgba(16,185,129,.15);color:var(--green);border:1px solid rgba(16,185,129,.4)}
.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:18px;margin-top:16px}
.card h2{font-size:16px;margin-bottom:6px}
.card .sub{font-size:12.5px;color:var(--muted)}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px}
@media(max-width:640px){.grid2,.grid3{grid-template-columns:1fr}}
/* شاشة الدخول */
.login-wrap{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
.login-box{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:34px;width:100%;max-width:380px;text-align:center;box-shadow:0 0 60px rgba(59,130,246,.12)}
.login-box .logo{font-size:26px;font-weight:900;color:var(--blue-light);margin-bottom:4px}
.login-box .tag{font-size:12.5px;color:var(--muted);margin-bottom:22px}
.err{background:rgba(220,38,38,.12);border:1px solid rgba(220,38,38,.4);color:var(--red);border-radius:8px;padding:9px 12px;font-size:13px;margin-bottom:12px}
.hint{font-size:11.5px;color:var(--muted);margin-top:14px}
.mono{font-family:Consolas,monospace;letter-spacing:1px}
.inline-form{display:flex;gap:8px;flex-wrap:wrap;align-items:flex-end}
.inline-form>div{flex:1;min-width:120px}
code.path{background:#0e1017;border:1px solid var(--border);border-radius:6px;padding:2px 8px;font-size:12px;color:var(--blue-light)}
</style>
</head>
<body>

<?php if (!$logged): ?>
<!-- ===================== شاشة الدخول ===================== -->
<div class="login-wrap">
  <form class="login-box" method="post" action="?">
    <div class="logo">Blue VIP</div>
    <div class="tag">بوابة إدارة المحتوى والاشتراكات</div>
    <?php if (!empty($loginError)): ?><div class="err"><?= htmlspecialchars($loginError) ?></div><?php endif; ?>
    <label>اسم المستخدم</label>
    <input name="login_user" required autofocus autocomplete="username">
    <label>كلمة المرور</label>
    <input name="login_pass" type="password" required autocomplete="current-password">
    <div style="margin-top:18px"><button class="btn" style="width:100%">تسجيل الدخول</button></div>
    <div class="hint">الدخول الافتراضي: admin / bluevip2025 — غيّره بعد أول دخول</div>
  </form>
</div>

<?php else: ?>
<!-- ===================== الهيكل الرئيسي ===================== -->
<div class="topbar">
  <span class="brand">⦿ Blue VIP</span>
  <span class="badge">لوحة الإدارة</span>
  <span class="spacer"></span>
  <a class="btn secondary small" href="?logout=1">خروج</a>
</div>
<div class="nav">
  <?php foreach (array(
    'dashboard' => 'اللوحة', 'categories' => 'الأقسام', 'channels' => 'القنوات',
    'media' => 'أفلام ومسلسلات', 'matches' => 'المباريات', 'codes' => 'أكواد VIP',
    'settings' => 'الإعدادات',
  ) as $k => $t): ?>
    <a class="<?= $page === $k ? 'active' : '' ?>" href="?page=<?= $k ?>"><?= $t ?></a>
  <?php endforeach; ?>
</div>

<div class="container">
<input type="hidden" id="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">

<script>
/* حفظ صف جدول: يجمع كل حقول الصف ويبني نموذجاً مؤقتاً ويرسله.
   نستخدمه لأن <form> داخل <tr> غير صالح في HTML والمتصفحات تخرجه من الجدول. */
function rowSave(el, doAction, page) {
  var tr = el.closest('tr');
  var f = document.createElement('form');
  f.method = 'post';
  f.style.display = 'none';
  function add(n, v) {
    var i = document.createElement('input');
    i.name = n; i.value = v;
    f.appendChild(i);
  }
  tr.querySelectorAll('input[name],select[name],textarea[name]').forEach(function (el) {
    if (el.type === 'checkbox') { add(el.name, el.checked ? '1' : '0'); }
    else { add(el.name, el.value); }
  });
  var has = function (n) { return !!f.querySelector('input[name="' + n + '"]'); };
  if (!has('csrf')) add('csrf', document.getElementById('csrf').value);
  if (!has('do')) add('do', doAction);
  if (!has('page')) add('page', page);
  document.body.appendChild(f);
  f.submit();
}
</script>

<?php // ================================================= لوحة القيادة
if ($page === 'dashboard'): ?>
  <div class="stats">
    <div class="stat"><div class="n"><?= $stats['channels'] ?></div><div class="t">قناة مباشرة</div></div>
    <div class="stat"><div class="n"><?= $stats['cats'] ?></div><div class="t">قسم</div></div>
    <div class="stat"><div class="n"><?= $stats['movies'] ?></div><div class="t">فيلم</div></div>
    <div class="stat"><div class="n"><?= $stats['series'] ?></div><div class="t">مسلسل</div></div>
    <div class="stat"><div class="n"><?= $stats['matches'] ?></div><div class="t">مباراة</div></div>
    <div class="stat"><div class="n" style="color:var(--red)"><?= $stats['live'] ?></div><div class="t">مباشر الآن</div></div>
    <div class="stat"><div class="n"><?= $stats['codes'] ?></div><div class="t">كود VIP</div></div>
    <div class="stat"><div class="n" style="color:var(--green)"><?= $stats['active'] ?></div><div class="t">جهاز مفعّل</div></div>
  </div>

  <div class="card">
    <h2>روابط التشغيل</h2>
    <p class="sub" style="margin:8px 0">الـ API العام الذي يستهلكه التطبيق:</p>
    <code class="path"><?= htmlspecialchars(bv_api_url('catalog')) ?></code>
    <code class="path"><?= htmlspecialchars(bv_api_url('matches')) ?></code>
    <code class="path"><?= htmlspecialchars(bv_api_url('activate')) ?></code>
    <p class="sub" style="margin-top:10px">ضع رابط هذا المجلد في <code class="path">app/lib/config.dart → apiBase</code> داخل مشروع التطبيق.</p>
  </div>

  <div class="card">
    <h2>آخر أكواد VIP المفعّلة</h2>
    <?php $recent = bv_db()->query("SELECT code, device_id, activated_at, expires_at FROM codes WHERE activated_at != '' ORDER BY id DESC LIMIT 6")->fetchAll(); ?>
    <?php if (!$recent): ?><p class="sub">لا توجد تفعيلات بعد.</p><?php else: ?>
    <div class="table-wrap"><table>
      <tr><th>الكود</th><th>الجهاز</th><th>التفعيل</th><th>الانتهاء</th></tr>
      <?php foreach ($recent as $r): ?>
      <tr><td class="mono"><?= htmlspecialchars($r['code']) ?></td>
          <td class="mono" style="font-size:11px"><?= htmlspecialchars(mb_substr($r['device_id'], 0, 12)) ?>…</td>
          <td><?= htmlspecialchars($r['activated_at']) ?></td>
          <td><?= $r['expires_at'] === '' ? '<span class="pill ok">دائم</span>' : htmlspecialchars($r['expires_at']) ?></td></tr>
      <?php endforeach; ?>
    </table></div>
    <?php endif; ?>
  </div>

<?php // ================================================= الأقسام
elseif ($page === 'categories'):
    $type = isset($_GET['type']) ? (string) $_GET['type'] : 'live';
    if (!in_array($type, array('live', 'movies', 'series'), true)) { $type = 'live'; }
    $st = bv_db()->prepare('SELECT * FROM categories WHERE type = ? ORDER BY sort, id');
    $st->execute(array($type));
    $rows = $st->fetchAll();
?>
  <div class="card">
    <h2>الأقسام</h2>
    <div class="inline-form" style="margin-top:10px">
      <a class="btn small <?= $type === 'live' ? '' : 'secondary' ?>" href="?page=categories&type=live">بث مباشر</a>
      <a class="btn small <?= $type === 'movies' ? '' : 'secondary' ?>" href="?page=categories&type=movies">أفلام</a>
      <a class="btn small <?= $type === 'series' ? '' : 'secondary' ?>" href="?page=categories&type=series">مسلسلات</a>
    </div>
    <form method="post" class="inline-form" style="margin-top:16px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="cat_add"><input type="hidden" name="page" value="categories">
      <input type="hidden" name="type" value="<?= htmlspecialchars($type) ?>">
      <div><label>اسم القسم</label><input name="name" required></div>
      <div><label>أيقونة (اختياري)</label><input name="icon" placeholder="star"></div>
      <div><label>ترتيب</label><input name="sort" type="number" value="0"></div>
      <div style="flex:0"><button class="btn">إضافة قسم</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>#</th><th>الاسم</th><th>الأيقونة</th><th>الترتيب</th><th></th></tr>
      <?php foreach ($rows as $r): ?>
      <tr>
        <input type="hidden" name="do" value="cat_edit">
        <input type="hidden" name="page" value="categories">
        <input type="hidden" name="type" value="<?= htmlspecialchars($type) ?>">
        <input type="hidden" name="id" value="<?= $r['id'] ?>">
        <td><?= $r['id'] ?></td>
        <td><input name="name" value="<?= htmlspecialchars($r['name']) ?>"></td>
        <td><input name="icon" value="<?= htmlspecialchars($r['icon']) ?>" style="max-width:110px"></td>
        <td><input name="sort" type="number" value="<?= $r['sort'] ?>" style="max-width:80px"></td>
        <td style="white-space:nowrap">
          <button class="btn small" type="button" onclick="rowSave(this,'cat_edit','categories')">حفظ</button>
          <a class="btn danger small" href="#" onclick="if(confirm('حذف القسم؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=cat_del><input name=page value=categories><input name=id value=<?= $r['id'] ?>><input name=type value=<?= $type ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$rows): ?><tr><td colspan="5" style="color:var(--muted)">لا توجد أقسام — أضف أول قسم.</td></tr><?php endif; ?>
    </table></div>
  </div>

<?php // ================================================= القنوات
elseif ($page === 'channels'):
    $cats = bv_db()->query("SELECT * FROM categories WHERE type = 'live' ORDER BY sort, id")->fetchAll();
    $catMap = array(); foreach ($cats as $c) { $catMap[$c['id']] = $c['name']; }
    $sel = bv_int('cat');
    if ($sel && isset($catMap[$sel])) {
        $st = bv_db()->prepare('SELECT * FROM channels WHERE category_id = ? ORDER BY sort, id');
        $st->execute(array($sel));
    } else {
        $st = bv_db()->query('SELECT * FROM channels ORDER BY category_id, sort, id');
    }
    $rows = $st->fetchAll();
?>
  <div class="card">
    <h2>القنوات</h2>
    <form method="get" class="inline-form" style="margin:12px 0">
      <input type="hidden" name="page" value="channels">
      <div style="max-width:260px"><label>تصفية حسب القسم</label>
        <select name="cat" onchange="this.form.submit()">
          <option value="0">كل الأقسام</option>
          <?php foreach ($catMap as $id => $n): ?>
          <option value="<?= $id ?>" <?= $sel === $id ? 'selected' : '' ?>><?= htmlspecialchars($n) ?></option>
          <?php endforeach; ?>
        </select></div>
    </form>
    <form method="post" class="inline-form">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="ch_add"><input type="hidden" name="page" value="channels">
      <div><label>القسم</label><select name="category_id">
        <?php foreach ($catMap as $id => $n): ?><option value="<?= $id ?>"><?= htmlspecialchars($n) ?></option><?php endforeach; ?>
      </select></div>
      <div><label>اسم القناة</label><input name="name" required></div>
      <div><label>رابط البث (m3u8/mp4)</label><input name="url" dir="ltr" required></div>
      <div><label>رابط احتياطي</label><input name="backup_url" dir="ltr"></div>
      <div style="flex:0"><button class="btn">إضافة</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>#</th><th>القسم</th><th>الاسم</th><th>الرابط</th><th>الترتيب</th><th>الحالة</th><th></th></tr>
      <?php foreach ($rows as $r): ?>
      <tr>
        <input type="hidden" name="do" value="ch_edit">
        <input type="hidden" name="page" value="channels">
        <input type="hidden" name="id" value="<?= $r['id'] ?>">
        <td><?= $r['id'] ?></td>
        <td><select name="category_id">
          <?php foreach ($catMap as $id => $n): ?><option value="<?= $id ?>" <?= (int) $r['category_id'] === (int) $id ? 'selected' : '' ?>><?= htmlspecialchars($n) ?></option><?php endforeach; ?>
        </select></td>
        <td><input name="name" value="<?= htmlspecialchars($r['name']) ?>"></td>
        <td><input name="url" dir="ltr" value="<?= htmlspecialchars($r['url']) ?>" style="min-width:180px"></td>
        <td><input name="sort" type="number" value="<?= $r['sort'] ?>" style="max-width:70px"></td>
        <td><select name="active"><option value="1" <?= $r['active'] ? 'selected' : '' ?>>نشط</option><option value="0" <?= !$r['active'] ? 'selected' : '' ?>>موقوف</option></select></td>
        <td style="white-space:nowrap">
          <button class="btn small" type="button" onclick="rowSave(this,'ch_edit','channels')">حفظ</button>
          <a class="btn danger small" href="#" onclick="if(confirm('حذف القناة؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=ch_del><input name=page value=channels><input name=id value=<?= $r['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$rows): ?><tr><td colspan="7" style="color:var(--muted)">لا توجد قنوات بعد.</td></tr><?php endif; ?>
    </table></div>
  </div>

<?php // ================================================= أفلام ومسلسلات
elseif ($page === 'media'):
    $type = isset($_GET['type']) && $_GET['type'] === 'series' ? 'series' : 'movie';
    $cats = bv_db()->prepare("SELECT * FROM categories WHERE type = ? ORDER BY sort, id");
    $cats->execute(array($type === 'movie' ? 'movies' : 'series'));
    $catMap = array(); foreach ($cats->fetchAll() as $c) { $catMap[$c['id']] = $c['name']; }
    $st = bv_db()->prepare('SELECT * FROM media WHERE type = ? ORDER BY sort, id DESC');
    $st->execute(array($type));
    $rows = $st->fetchAll();
    $eps = bv_db()->query('SELECT * FROM episodes ORDER BY season, number')->fetchAll();
    $epsByMedia = array(); foreach ($eps as $e) { $epsByMedia[$e['media_id']][] = $e; }
?>
  <div class="card">
    <h2>أفلام ومسلسلات</h2>
    <div class="inline-form" style="margin-top:10px">
      <a class="btn small <?= $type === 'movie' ? '' : 'secondary' ?>" href="?page=media&type=movie">أفلام</a>
      <a class="btn small <?= $type === 'series' ? '' : 'secondary' ?>" href="?page=media&type=series">مسلسلات</a>
    </div>
    <form method="post" class="inline-form" style="margin-top:16px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="media_add"><input type="hidden" name="page" value="media">
      <input type="hidden" name="type" value="<?= htmlspecialchars($type) ?>">
      <div><label>الاسم</label><input name="name" required></div>
      <div><label>القسم</label><select name="category_id"><option value="0">بدون قسم</option>
        <?php foreach ($catMap as $id => $n): ?><option value="<?= $id ?>"><?= htmlspecialchars($n) ?></option><?php endforeach; ?>
      </select></div>
      <div><label><?= $type === 'movie' ? 'رابط الفيلم' : 'رابط الحلقة الأولى (اختياري)' ?></label><input name="url" dir="ltr"></div>
      <div style="flex:0"><button class="btn">إضافة</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>#</th><th>الاسم</th><th>السنة</th><th>التقييم</th><th><?= $type === 'series' ? 'الحلقات' : 'الرابط' ?></th><th></th></tr>
      <?php foreach ($rows as $r): ?>
      <tr>
        <input type="hidden" name="do" value="media_edit">
        <input type="hidden" name="page" value="media">
        <input type="hidden" name="type" value="<?= htmlspecialchars($type) ?>">
        <input type="hidden" name="id" value="<?= $r['id'] ?>">
        <td><?= $r['id'] ?></td>
        <td><input name="name" value="<?= htmlspecialchars($r['name']) ?>"></td>
        <td><input name="year" value="<?= htmlspecialchars($r['year']) ?>" style="max-width:80px"></td>
        <td><input name="rating" type="number" step="0.1" max="10" value="<?= $r['rating'] ?>" style="max-width:70px"></td>
        <td>
          <?php if ($type === 'series'): ?>
            <span class="pill upcoming"><?= isset($epsByMedia[$r['id']]) ? count($epsByMedia[$r['id']]) : 0 ?> حلقة</span>
            <a class="btn secondary small" href="?page=media&type=series&eps=<?= $r['id'] ?>#eps">إدارة</a>
          <?php else: ?>
            <input name="url" dir="ltr" value="<?= htmlspecialchars($r['url']) ?>" style="min-width:180px">
          <?php endif; ?>
        </td>
        <td style="white-space:nowrap">
          <button class="btn small" type="button" onclick="rowSave(this,'media_edit','media')">حفظ</button>
          <a class="btn danger small" href="#" onclick="if(confirm('حذف؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=media_del><input name=page value=media><input name=type value=<?= $type ?>><input name=id value=<?= $r['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$rows): ?><tr><td colspan="6" style="color:var(--muted)">لا توجد عناصر بعد.</td></tr><?php endif; ?>
    </table></div>
  </div>

  <?php // إدارة حلقات مسلسل محدد
  $epsMediaId = isset($_GET['eps']) ? (int) $_GET['eps'] : 0;
  if ($type === 'series' && $epsMediaId):
      $stM = bv_db()->prepare('SELECT * FROM media WHERE id = ? AND type = "series"');
      $stM->execute(array($epsMediaId));
      $media = $stM->fetch();
      if ($media):
      $mediaEps = isset($epsByMedia[$epsMediaId]) ? $epsByMedia[$epsMediaId] : array();
  ?>
  <div class="card" id="eps">
    <h2>حلقات: <?= htmlspecialchars($media['name']) ?></h2>
    <form method="post" class="inline-form" style="margin-top:12px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="ep_add"><input type="hidden" name="page" value="media">
      <input type="hidden" name="type" value="series"><input type="hidden" name="eps" value="<?= $epsMediaId ?>">
      <input type="hidden" name="media_id" value="<?= $epsMediaId ?>">
      <div style="max-width:90px"><label>موسم</label><input name="season" type="number" value="1" min="1"></div>
      <div style="max-width:90px"><label>حلقة</label><input name="number" type="number" value="1" min="1"></div>
      <div><label>اسم الحلقة</label><input name="name"></div>
      <div><label>الرابط</label><input name="url" dir="ltr" required></div>
      <div style="flex:0"><button class="btn">إضافة حلقة</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>موسم</th><th>حلقة</th><th>الاسم</th><th>الرابط</th><th></th></tr>
      <?php foreach ($mediaEps as $e): ?>
      <tr><td><?= $e['season'] ?></td><td><?= $e['number'] ?></td><td><?= htmlspecialchars($e['name']) ?></td>
          <td style="max-width:260px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" dir="ltr"><?= htmlspecialchars($e['url']) ?></td>
          <td><a class="btn danger small" href="#" onclick="if(confirm('حذف الحلقة؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=ep_del><input name=page value=media><input name=type value=series><input name=eps value=<?= $epsMediaId ?>><input name=id value=<?= $e['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a></td></tr>
      <?php endforeach; ?>
      <?php if (!$mediaEps): ?><tr><td colspan="5" style="color:var(--muted)">لا توجد حلقات.</td></tr><?php endif; ?>
    </table></div>
    <a class="btn secondary small" style="margin-top:12px" href="?page=media&type=series">رجوع للمسلسلات</a>
  </div>
  <?php endif; endif; ?>

<?php // ================================================= المباريات
elseif ($page === 'matches'):
    $rows = bv_db()->query('SELECT * FROM matches ORDER BY starts_at DESC, id DESC')->fetchAll();
    $servers = bv_db()->query('SELECT * FROM match_servers ORDER BY id')->fetchAll();
    $srvByMatch = array(); foreach ($servers as $s) { $srvByMatch[$s['match_id']][] = $s; }
    $statuses = array('live' => 'مباشر الآن', 'upcoming' => 'لم تبدأ', 'finished' => 'انتهت');
?>
  <div class="card">
    <h2>المباريات</h2>
    <form method="post" class="inline-form" style="margin-top:12px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="match_add"><input type="hidden" name="page" value="matches">
      <div><label>المباراة (الهندسة × القوة الجوية)</label><input name="title" required></div>
      <div><label>البطولة</label><input name="league"></div>
      <div><label>التاريخ والوقت</label><input name="starts_at" placeholder="<?= date('Y-m-d') ?> 20:00"></div>
      <div style="max-width:130px"><label>الحالة</label><select name="status">
        <option value="upcoming">لم تبدأ</option><option value="live">مباشر الآن</option><option value="finished">انتهت</option>
      </select></div>
      <div style="flex:0"><button class="btn">إضافة</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>#</th><th>المباراة</th><th>البطولة</th><th>الوقت</th><th>الحالة</th><th>السيرفرات</th><th></th></tr>
      <?php foreach ($rows as $r): ?>
      <tr>
        <input type="hidden" name="do" value="match_edit">
        <input type="hidden" name="page" value="matches">
        <input type="hidden" name="id" value="<?= $r['id'] ?>">
        <td><?= $r['id'] ?></td>
        <td><input name="title" value="<?= htmlspecialchars($r['title']) ?>" style="min-width:180px"></td>
        <td><input name="league" value="<?= htmlspecialchars($r['league']) ?>" style="max-width:130px"></td>
        <td><input name="starts_at" value="<?= htmlspecialchars($r['starts_at']) ?>" style="max-width:150px"></td>
        <td><select name="status">
          <?php foreach ($statuses as $k => $t): ?><option value="<?= $k ?>" <?= $r['status'] === $k ? 'selected' : '' ?>><?= $t ?></option><?php endforeach; ?>
        </select></td>
        <td><?= isset($srvByMatch[$r['id']]) ? count($srvByMatch[$r['id']]) : 0 ?>
            <a class="btn secondary small" href="?page=matches&servers=<?= $r['id'] ?>#srv">إدارة</a></td>
        <td style="white-space:nowrap">
          <button class="btn small" type="button" onclick="rowSave(this,'match_edit','matches')">حفظ</button>
          <a class="btn danger small" href="#" onclick="if(confirm('حذف المباراة وسيرفراتها؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=match_del><input name=page value=matches><input name=id value=<?= $r['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$rows): ?><tr><td colspan="7" style="color:var(--muted)">لا توجد مباريات.</td></tr><?php endif; ?>
    </table></div>
  </div>

  <?php $srvMatchId = isset($_GET['servers']) ? (int) $_GET['servers'] : 0;
  if ($srvMatchId):
      $stM = bv_db()->prepare('SELECT * FROM matches WHERE id = ?');
      $stM->execute(array($srvMatchId));
      $m = $stM->fetch();
      if ($m):
      $ms = isset($srvByMatch[$srvMatchId]) ? $srvByMatch[$srvMatchId] : array();
  ?>
  <div class="card" id="srv">
    <h2>سيرفرات البث: <?= htmlspecialchars($m['title']) ?></h2>
    <form method="post" class="inline-form" style="margin-top:12px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="srv_add"><input type="hidden" name="page" value="matches">
      <input type="hidden" name="servers" value="<?= $srvMatchId ?>">
      <input type="hidden" name="match_id" value="<?= $srvMatchId ?>">
      <div><label>اسم السيرفر</label><input name="name" value="سيرفر <?= count($ms) + 1 ?> (HD)"></div>
      <div style="max-width:100px"><label>الجودة</label><select name="quality"><option>HD</option><option>SD</option><option>FHD</option></select></div>
      <div><label>الرابط</label><input name="url" dir="ltr" required></div>
      <div style="flex:0"><button class="btn">إضافة سيرفر</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>الاسم</th><th>الجودة</th><th>الرابط</th><th></th></tr>
      <?php foreach ($ms as $s): ?>
      <tr><td><?= htmlspecialchars($s['name']) ?></td><td><?= htmlspecialchars($s['quality']) ?></td>
          <td style="max-width:280px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" dir="ltr"><?= htmlspecialchars($s['url']) ?></td>
          <td><a class="btn danger small" href="#" onclick="if(confirm('حذف السيرفر؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=srv_del><input name=page value=matches><input name=servers value=<?= $srvMatchId ?>><input name=id value=<?= $s['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a></td></tr>
      <?php endforeach; ?>
      <?php if (!$ms): ?><tr><td colspan="4" style="color:var(--muted)">لا توجد سيرفرات — أضف أول سيرفر بث.</td></tr><?php endif; ?>
    </table></div>
    <a class="btn secondary small" style="margin-top:12px" href="?page=matches">رجوع للمباريات</a>
  </div>
  <?php endif; endif; ?>

<?php // ================================================= أكواد VIP
elseif ($page === 'codes'):
    $rows = bv_db()->query('SELECT * FROM codes ORDER BY id DESC LIMIT 200')->fetchAll();
?>
  <div class="card">
    <h2>أكواد VIP</h2>
    <p class="sub">ولّد أكواد تفعيل وابعتها للمشتركين — كل كود يشتغل على جهاز واحد حسب المدة.</p>
    <form method="post" class="inline-form" style="margin-top:14px">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="code_gen"><input type="hidden" name="page" value="codes">
      <div style="max-width:100px"><label>العدد</label><input name="count" type="number" value="5" min="1" max="50"></div>
      <div style="max-width:100px"><label>المدة (يوم)</label><input name="days" type="number" value="30" min="1"></div>
      <div><label>ملاحظة (اسم المشترك مثلاً)</label><input name="note"></div>
      <div style="flex:0"><button class="btn">توليد أكواد</button></div>
    </form>
    <div class="table-wrap"><table>
      <tr><th>الكود</th><th>المدة</th><th>الحالة</th><th>الجهاز</th><th>الانتهاء</th><th>ملاحظة</th><th></th></tr>
      <?php foreach ($rows as $r):
        $used = $r['device_id'] !== '';
        $expired = $used && $r['expires_at'] !== '' && $r['expires_at'] < date('Y-m-d H:i');
      ?>
      <tr>
        <td class="mono" style="color:var(--blue-light)"><?= htmlspecialchars($r['code']) ?></td>
        <td><?= $r['days'] ?> يوم</td>
        <td><?php if (!$used): ?><span class="pill upcoming">غير مستخدم</span>
            <?php elseif ($expired): ?><span class="pill finished">منتهي</span>
            <?php else: ?><span class="pill ok">مفعّل</span><?php endif; ?></td>
        <td class="mono" style="font-size:11px"><?= $used ? htmlspecialchars(mb_substr($r['device_id'], 0, 12)) . '…' : '—' ?></td>
        <td><?= $r['expires_at'] === '' ? '—' : htmlspecialchars($r['expires_at']) ?></td>
        <td><?= htmlspecialchars($r['note']) ?></td>
        <td style="white-space:nowrap">
          <?php if ($used): ?>
          <a class="btn secondary small" href="#" onclick="if(confirm('فك الجهاز وإعادة تعيين الكود؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=code_reset><input name=page value=codes><input name=id value=<?= $r['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">إعادة تعيين</a>
          <?php endif; ?>
          <a class="btn danger small" href="#" onclick="if(confirm('حذف الكود؟')){var f=document.createElement('form');f.method='post';f.innerHTML='<input name=csrf value=<?= htmlspecialchars(bv_csrf()) ?>><input name=do value=code_del><input name=page value=codes><input name=id value=<?= $r['id'] ?>>';document.body.appendChild(f);f.submit();}return false;">حذف</a>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$rows): ?><tr><td colspan="7" style="color:var(--muted)">لا توجد أكواد — ولّد أول دفعة.</td></tr><?php endif; ?>
    </table></div>
  </div>

<?php // ================================================= الإعدادات
elseif ($page === 'settings'): ?>
  <div class="card">
    <h2>إعدادات التطبيق</h2>
    <p class="sub">هذه القيم تصل للتطبيق مباشرة عبر الـ API (action=config).</p>
    <form method="post">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="settings_save"><input type="hidden" name="page" value="settings">
      <div class="grid2">
        <div><label>اسم التطبيق</label><input name="app_name" value="<?= htmlspecialchars(bv_setting('app_name')) ?>"></div>
        <div><label>التاغلاين</label><input name="tagline" value="<?= htmlspecialchars(bv_setting('tagline')) ?>"></div>
        <div><label>رابط قناة التلغرام</label><input name="telegram_url" dir="ltr" value="<?= htmlspecialchars(bv_setting('telegram_url')) ?>"></div>
        <div><label>آخر إصدار</label><input name="latest_version" value="<?= htmlspecialchars(bv_setting('latest_version')) ?>"></div>
        <div><label>رابط آخر APK (للتحديث الذاتي)</label><input name="latest_apk_url" dir="ltr" value="<?= htmlspecialchars(bv_setting('latest_apk_url')) ?>"></div>
        <div><label>إجبار تفعيل VIP</label><select name="requires_activation">
          <option value="0" <?= bv_setting('requires_activation') !== '1' ? 'selected' : '' ?>>متعطل — التصفح مجاني</option>
          <option value="1" <?= bv_setting('requires_activation') === '1' ? 'selected' : '' ?>>مفعّل — يشترط كود VIP</option>
        </select></div>
      </div>
      <label>إشعار يظهر في التطبيق (فارغ = لا إشعار)</label>
      <textarea name="notice" rows="2"><?= htmlspecialchars(bv_setting('notice')) ?></textarea>
      <div style="margin-top:14px"><button class="btn">حفظ الإعدادات</button></div>
    </form>
  </div>

  <div class="card">
    <h2>حساب المدير</h2>
    <form method="post">
      <input type="hidden" name="csrf" value="<?= htmlspecialchars(bv_csrf()) ?>">
      <input type="hidden" name="do" value="admin_save"><input type="hidden" name="page" value="settings">
      <div class="grid2">
        <div><label>اسم المستخدم</label><input name="admin_user" value="<?= htmlspecialchars(bv_setting('admin_user')) ?>"></div>
        <div><label>كلمة مرور جديدة (اتركها فارغة للإبقاء — 6 خانات+)</label><input name="admin_pass" type="password" autocomplete="new-password"></div>
      </div>
      <div style="margin-top:14px"><button class="btn">حفظ حساب المدير</button></div>
    </form>
  </div>
<?php endif; ?>

<div style="height:40px"></div>
</div>
<?php endif; ?>

</body>
</html>
