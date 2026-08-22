<?php

if (isset($_GET['path']) && is_string($_GET['path'])) {
	$path = '/'.ltrim($_GET['path'], '/');

	if (!str_starts_with($path, '/api/')) {
		$path = '/api'.$path;
	}

	$_SERVER['REQUEST_URI'] = $path;
	$_SERVER['PATH_INFO'] = $path;
}

require __DIR__.'/../public/index.php';
