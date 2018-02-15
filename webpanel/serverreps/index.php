<!--
CREATED BY 
Skillkiller (github.com/skillkiller), 
Argex, 
Lucsoft (github.com/lucsoft), 
zekro (github.com/zekrotja)
© 2018 zekro's Dev-Schuppen (discord.zekro.de)
-->

<!DOCTYPE html>
<html lang="en" >

<head>
  <meta charset="UTF-8">
  <title>Repots</title>
  <?php require "../php/main.php" ?>
  <link rel="stylesheet" href="css/style.css">
</head>

<body>
  <?php
  error_reporting(0);
  $user = "";
  $pw = "";
  $server = "";
  $db = "";

  if (!isset($_GET['victim'])) {
    echo "Es wurde kein Nutzer angeben!";
    return;
  }

  $victimid = $_GET['victim'];

  $mysqli = new mysqli($server, $user, $pw, $db);
  if ($mysqli->connect_errno) {
    die("Verbindung fehlgeschlagen: " . $mysqli->connect_error);
  }
  if(!$mysqli->set_charset("utf8")) {
    printf("Error loading character set utf8: %s\n", $mysqli->error);
    exit();
  }


  $sql = "SELECT * FROM reports WHERE victim = ?";
  $statement = $mysqli->prepare($sql);
  $statement->bind_param('i', $victimid);
  $statement->execute();
  $statement->bind_result($victimid, $reporter, $date, $reason);
  $statement->store_result();
  $count = $statement->num_rows();
  ?>


  <div class="grid">
    <div class="kopf"><h1>Report<?php if($count >= 2) echo "s";?> (<?php echo $count?>) von <?php echo $victimid ?></h1></div>
    <div id="reports">
      <?php
        while($statement->fetch()) {
          $reason = trim(str_replace("\n", "<br />", $reason));
          ?>
          <div class="report">
            <div class="datum">
              <table>
                <tbody>
                  <tr>
                    <td scope="row" style="font-weight: bold; padding-right: 10px;">Date</th>
                    <td><?php echo $date ?></td>
                  </tr>
                  <tr>
                    <td scope="row" style="font-weight: bold; padding-right: 10px;">Creator</th>
                    <td><?php echo $reporter ?></td>
                  </tr>
              </table>
            </div>
            <div class="grund">
                        <?php echo $reason ?>
            </div>
          </div>

          <?php
        }
      $statement->close();
      ?>
    </div>
  </div>
  <br>
<footer>© 2018 - Report Overview by zekro's Dev-Schuppen</footer>



</body>

</html>
