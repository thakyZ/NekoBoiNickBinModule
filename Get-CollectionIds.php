<?php
/**
 * Test Script
 * A small test script
 * A test script to test steam web api test shit.
 *
 * PHP version 7
 *
 * @category Test
 * @package  Test
 * @author   thakyZ <nekoboinick@gmail.com>
 * @license  https://www.gnu.org/licenses/gpl-3.0.txt GNU/GPLv3
 * @link     null
 */

/**
 * Matches a string with a pattern
 *
 * @param string $source  The string to match
 * @param string $pattern The pattern to match
 *
 * @return bool
 */
function stringMatch($source, $pattern)
{
    $pattern = preg_quote($pattern, "/");
    $pattern = str_replace("\*", ".*?", $pattern);
    //> This is the important replace
    return (bool)preg_match("/^" . $pattern . "$/i", $source);
}

$config_file = file_get_contents(dirname(__FILE__) . "config.json");
$config_json = json_decode($config_file, true);

$login_url = "https://steamcommunity.com/login/getrsakey/";
$login_params = ["username" => $config_json["steam"]["username"], "password" => $config_json["steam"]["password"]];

$cookie_jar = dirname(__FILE__) . "\.cookietmp";

$session = curl_init($login_url);

curl_setopt($session, CURLOPT_POST, true);
curl_setopt($session, CURLOPT_POSTFIELDS, $login_params);
curl_setopt($session, CURLOPT_HEADER, false);
curl_setopt($session, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($session, CURLOPT_RETURNTRANSFER, true);
curl_setopt($session, CURLOPT_TIMEOUT, 30);
curl_setopt($session, CURLOPT_MAXREDIRS, 10);
curl_setopt($session, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($session, CURLOPT_COOKIEJAR, $cookie_jar);

$response = curl_exec($session);
$resArr = array();
$resArr = json_decode($response);
//var_dump($response);
//var_dump($resArr);
curl_close($session);

$collection_id = "1593754305";
$collection_url = "https://steamcommunity.com/sharedfiles/filedetails/?id=" . $collection_id;

$collection_session = curl_init($collection_url);

curl_setopt($collection_session, CURLOPT_RETURNTRANSFER, true);
curl_setopt($collection_session, CURLOPT_HEADER, false);
curl_setopt($collection_session, CURLOPT_TIMEOUT, 30);
curl_setopt($collection_session, CURLOPT_COOKIEJAR, $cookie_jar);
curl_setopt($collection_session, CURLOPT_SSL_VERIFYPEER, true);

$html = curl_exec($collection_session);

if (curl_error($collection_session)) {
    die(curl_error($collection_session));
}

$status = curl_getinfo($collection_session, CURLINFO_HTTP_CODE);

//var_dump($html);

curl_close($collection_session);

$dom = new DOMDocument;
@$dom->loadHTML($html);

$links = $dom->getElementsByTagName("a");

$mod_id_collection = array();
//$mod_desc_collection = array();

foreach ($links as $link) {
    $inner_html = "";
    $inner_html .= $dom->saveHTML($link);
    if (stringMatch($inner_html, "*workshopItemTitle*")) {
        $mod_id = str_replace("https://steamcommunity.com/sharedfiles/filedetails/?id=", "", $link->getAttribute("href"));
        if (!(in_array($mod_id, $mod_id_collection))) {
            //$desc = $link->textContent;
            //array_push($mod_desc_collection, $desc);
            array_push($mod_id_collection, $mod_id);
        }
    }
}
//var_dump($mod_desc_collection);
//var_dump($mod_id_collection);

//$json_desc_collection = json_encode($mod_desc_collection);
$json_id_collection = json_encode($mod_id_collection);

//var_dump($json_desc_collection);
var_dump($json_id_collection);
?>
