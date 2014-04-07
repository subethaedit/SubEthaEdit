<td width="219" bgcolor="#FFFF99"><select name="post_type" id="post_type" onchange="update_postage_sum();">
    <option selected="selected" value="">Auswahl:</option>
    <option value="u<? echo $_SESSION['LoginData']['upszone']?>">UPS Standard (Zone <? echo $_SESSION['LoginData']['upszone']?>)</option>
    <option value="p<? echo $_SESSION['LoginData']['postzone']?>">Post (Zone <? echo $_SESSION['LoginData']['postzone']?>)</option>
    <option value="u1">UPS Standard (DE) </option>
    <option value="p0">Post (DE) </option>
    <option value="Abholung">Abholung</option>
</select></td>
