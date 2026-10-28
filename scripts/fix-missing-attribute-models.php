<?php
// EAV attributes created by extensions that are not installed (e.g. Facebook, Amasty, Plumrocket) keep pointing
// to their model classes, and Magento fails with "Class ... does not exist" (e.g. on the admin product edit page).
// This clears every missing source/backend/frontend model. Product dropdowns with a missing source model become
// text fields, so their stored values stay visible and are not wiped when a product is saved.
// Prints restore SQL for the original values (to bring them back once the extension is installed again).
// Idempotent. Run: docker compose exec -T php php < scripts/fix-missing-attribute-models.php > backups/attribute-models-restore.sql
use Magento\Framework\App\Bootstrap;

require '/var/www/html/app/bootstrap.php';
$om = Bootstrap::create(BP, $_SERVER)->getObjectManager();
$db = $om->get(\Magento\Framework\App\ResourceConnection::class)->getConnection();
$eav = $db->getTableName('eav_attribute');
$catalogEav = $db->getTableName('catalog_eav_attribute');

$rows = $db->fetchAll(
    "SELECT a.attribute_id, a.attribute_code, t.entity_type_code, a.frontend_input,
            a.source_model, a.backend_model, a.frontend_model, c.frontend_input_renderer
     FROM $eav a
     JOIN {$db->getTableName('eav_entity_type')} t ON t.entity_type_id = a.entity_type_id
     LEFT JOIN $catalogEav c ON c.attribute_id = a.attribute_id"
);

$changed = 0;
echo "-- Restore original attribute models (generated " . date('c') . ")\n";
foreach ($rows as $row) {
    $missing = [];
    foreach (['source_model', 'backend_model', 'frontend_model', 'frontend_input_renderer'] as $column) {
        if ($row[$column] && !class_exists($row[$column])) {
            $missing[] = $column;
        }
    }
    if (!$missing) {
        continue;
    }
    $id = (int)$row['attribute_id'];
    $eavUpdate = [];
    $restore = [];
    foreach (array_diff($missing, ['frontend_input_renderer']) as $column) {
        $eavUpdate[$column] = null;
        $restore[] = "$column = " . $db->quote($row[$column]);
    }
    $toText = in_array('source_model', $missing, true)
        && $row['entity_type_code'] === 'catalog_product'
        && in_array($row['frontend_input'], ['select', 'multiselect'], true);
    if ($toText) {
        $eavUpdate['frontend_input'] = 'text';
        $restore[] = 'frontend_input = ' . $db->quote($row['frontend_input']);
    }
    if ($eavUpdate) {
        $db->update($eav, $eavUpdate, ['attribute_id = ?' => $id]);
        echo "UPDATE $eav SET " . implode(', ', $restore) . " WHERE attribute_id = $id; -- {$row['entity_type_code']}.{$row['attribute_code']}\n";
    }
    if (in_array('frontend_input_renderer', $missing, true)) {
        $db->update($catalogEav, ['frontend_input_renderer' => null], ['attribute_id = ?' => $id]);
        echo "UPDATE $catalogEav SET frontend_input_renderer = " . $db->quote($row['frontend_input_renderer'])
            . " WHERE attribute_id = $id; -- {$row['attribute_code']}\n";
    }
    fwrite(STDERR, sprintf("fixed %s.%s: %s%s\n", $row['entity_type_code'], $row['attribute_code'],
        implode(', ', $missing), $toText ? ' (select -> text)' : ''));
    $changed++;
}
fwrite(STDERR, $changed ? "$changed attribute(s) fixed - run bin/magento cache:flush\n" : "No attributes with missing models.\n");
