<!DOCTYPE html>
<html>
	<head>
		<?php 
			// HTTPS redirect
			if (!isset($_SERVER['HTTPS']))
				header("Location: https://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]")
		?>

		<title>knechtV2 Webpanel | User Stats</title>
		<style>
			.chart-container {
				width: auto;
				height: auto;
				margin: 10px 100px 10px 10px;
			}
		</style>
		<link rel="shortcut icon" type="image/png" href="../src/favicon.png"/>
	</head>
	<body>
		<div class="chart-container">
			<canvas id="mycanvas"></canvas>
		</div>
		
		<!-- javascript -->
		<script type="text/javascript" src="js/jquery.min.js"></script>
		<script type="text/javascript" src="js/Chart.min.js"></script>
		<script type="text/javascript" src="js/linegraph.js"></script>
	</body>
</html>