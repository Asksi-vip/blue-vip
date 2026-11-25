<?php
/**
 * Blue VIP — الـ API العام (JSON) الذي يستهلكه التطبيق مباشرة.
 *
 * GET/POST api/index.php?action=...
 *   config   → إعدادات التطبيق (اسم، تلغرام، تحديث، إشعار، إجبار تفعيل)
 *   catalog  → الأقسام والقنوات (نفس بنية كتالوج IraqMax المدمج)
 *   movies   → قائمة الأفلام
 *   series   → قائمة المسلسلات مع الحلقات
 *   matches  → جدول المباريات مع سيرفرات البث لكل مباراة
 *   status   → حالة تفعيل جهاز (device_id)
 *   activate → تفعيل كود VIP على جهاز (code + device_id)
 */

require_once __DIR__ . '/../includes/db.php';

$action = bv_str('action', 40);

switch ($action) {

    // ---------- إعدادات التطبيق ----------
    case 'config':
        bv_json(array(
            'ok' => true,
            'app_name' => bv_setting('app_name', 'Blue VIP'),
            'tagline' => bv_setting('tagline'),
            'telegram_url' => bv_setting('telegram_url'),
            'latest_version' => bv_setting('latest_version'),
            'latest_apk_url' => bv_setting('latest_apk_url'),
            'requires_activation' => bv_setting('requires_activation') === '1',
            'notice' => bv_setting('notice'),
        ));
        break;

    // ---------- الكتالوج: أقسام + قنوات ----------
    case 'catalog': {
        $cats = bv_db()->query(
            "SELECT id, name, icon FROM categories WHERE type = 'live' ORDER BY sort, id"
        )->fetchAll();
        $chs = bv_db()->query(
            "SELECT id, category_id, name, logo, url, backup_url
             FROM channels WHERE active = 1 ORDER BY sort, id"
        )->fetchAll();
        $out = array();
        foreach ($chs as $c) {
            $out[] = array(
                'id' => 'bv_' . $c['id'],
                'name' => $c['name'],
                'category_id' => 'bvcat_' . $c['category_id'],
                'logo' => $c['logo'],
                'url' => $c['url'],
                'backup_url' => $c['backup_url'],
            );
        }
        $catOut = array();
        foreach ($cats as $c) {
            $catOut[] = array(
                'id' => 'bvcat_' . $c['id'],
                'name' => $c['name'],
                'icon' => $c['icon'],
            );
        }
        bv_json(array(
            'version' => 1,
            'source' => 'BLUE_VIP_OFFICIAL_API',
            'updated_at' => date('c'),
            'categories' => $catOut,
            'channels' => $out,
        ));
        break;
    }

    // ---------- الأفلام ----------
    case 'movies': {
        $rows = bv_db()->query(
            "SELECT m.id, m.name, m.poster, m.url, m.year, m.rating, m.description,
                    c.name AS category
             FROM media m LEFT JOIN categories c ON c.id = m.category_id
             WHERE m.type = 'movie' ORDER BY m.sort, m.id DESC"
        )->fetchAll();
        bv_json(array('ok' => true, 'items' => $rows));
        break;
    }

    // ---------- المسلسلات مع الحلقات ----------
    case 'series': {
        $rows = bv_db()->query(
            "SELECT m.id, m.name, m.poster, m.year, m.rating, m.description,
                    c.name AS category
             FROM media m LEFT JOIN categories c ON c.id = m.category_id
             WHERE m.type = 'series' ORDER BY m.sort, m.id DESC"
        )->fetchAll();
        $epSt = bv_db()->prepare(
            'SELECT season, number, name, url FROM episodes WHERE media_id = ?
             ORDER BY season, number'
        );
        foreach ($rows as &$r) {
            $epSt->execute(array($r['id']));
            $r['episodes'] = $epSt->fetchAll();
        }
        bv_json(array('ok' => true, 'items' => $rows));
        break;
    }

    // ---------- جدول المباريات + السيرفرات ----------
    case 'matches': {
        $rows = bv_db()->query(
            'SELECT id, title, team_a, team_b, league, starts_at, status
             FROM matches ORDER BY
               CASE status WHEN "live" THEN 0 WHEN "upcoming" THEN 1 ELSE 2 END,
               starts_at, id'
        )->fetchAll();
        $srvSt = bv_db()->prepare(
            'SELECT name, url, quality FROM match_servers WHERE match_id = ? ORDER BY id'
        );
        foreach ($rows as &$m) {
            $srvSt->execute(array($m['id']));
            $m['servers'] = $srvSt->fetchAll();
        }
        bv_json(array('ok' => true, 'matches' => $rows));
        break;
    }

    // ---------- حالة تفعيل جهاز ----------
    case 'status': {
        $device = bv_str('device_id', 80);
        if ($device === '') {
            bv_json(array('ok' => false, 'error' => 'device_id مطلوب'), 400);
        }
        $st = bv_db()->prepare(
            "SELECT code, expires_at FROM codes WHERE device_id = ? AND activated_at != ''"
        );
        $st->execute(array($device));
        $row = $st->fetch();
        $active = false;
        $expires = '';
        if ($row) {
            // التفعيل صالح إن لم يوجد تاريخ انتهاء (دائم) أو التاريخ لم يمر
            if ($row['expires_at'] === '' || $row['expires_at'] >= date('Y-m-d H:i')) {
                $active = true;
                $expires = $row['expires_at'];
            }
        }
        bv_json(array('ok' => true, 'active' => $active, 'expires_at' => $expires));
        break;
    }

    // ---------- تفعيل كود VIP على جهاز ----------
    case 'activate': {
        $code = strtoupper(bv_str('code', 40));
        $device = bv_str('device_id', 80);
        if ($code === '' || $device === '') {
            bv_json(array('ok' => false, 'error' => 'أدخل كود التفعيل'), 400);
        }
        $st = bv_db()->prepare('SELECT * FROM codes WHERE code = ?');
        $st->execute(array($code));
        $row = $st->fetch();
        if (!$row) {
            bv_json(array('ok' => false, 'error' => 'الكود غير موجود — تحقق من الرمز'), 404);
        }
        // كود مربوط بجهاز آخر → رفض
        if ($row['device_id'] !== '' && $row['device_id'] !== $device) {
            bv_json(array('ok' => false, 'error' => 'هذا الكود مفعّل على جهاز آخر'), 403);
        }
        // أول تفعيل: احسب تاريخ الانتهاء من مدة الأيام
        $expires = $row['expires_at'];
        if ($row['device_id'] === '') {
            $days = max(1, (int) $row['days']);
            $expires = date('Y-m-d H:i', strtotime("+{$days} days"));
            bv_db()->prepare(
                'UPDATE codes SET device_id = ?, activated_at = ?, expires_at = ? WHERE id = ?'
            )->execute(array($device, date('Y-m-d H:i'), $expires, $row['id']));
        }
        // كود منتهي مسبقاً؟
        if ($expires !== '' && $expires < date('Y-m-d H:i')) {
            bv_json(array('ok' => false, 'error' => 'انتهت صلاحية هذا الكود'), 403);
        }
        bv_json(array(
            'ok' => true,
            'active' => true,
            'expires_at' => $expires,
            'message' => 'تم تفعيل اشتراك VIP بنجاح',
        ));
        break;
    }

    default:
        bv_json(array(
            'ok' => false,
            'error' => 'action غير معروف — الإجراءات: config, catalog, movies, series, matches, status, activate',
        ), 404);
}
