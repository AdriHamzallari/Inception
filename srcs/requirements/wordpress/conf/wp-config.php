<?php

define('DB_NAME', getenv('MYSQL_DATABASE'));

define('DB_USER', getenv('MYSQL_USER'));

define(
    'DB_PASSWORD',
    trim(file_get_contents('/run/wordpress/db_password'))
);

define('DB_HOST', getenv('MYSQL_HOST'));

define('DB_CHARSET', 'utf8mb4');

define('DB_COLLATE', '');

$table_prefix = 'wp_';

define('WP_DEBUG', false);

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';