<?php
// Creates/updates PL (default), UK and DE websites with the same codes as production. Idempotent.
// Run: docker compose exec -T php php < scripts/create-websites.php
use Magento\Framework\App\Bootstrap;
use Magento\Store\Model\Group;
use Magento\Store\Model\Store;
use Magento\Store\Model\Website;

require '/var/www/html/app/bootstrap.php';
$om = Bootstrap::create(BP, $_SERVER)->getObjectManager();
$om->get(\Magento\Framework\App\State::class)->setAreaCode('adminhtml');

$sites = [
    // website code => [website name, group code, group name, store code, store view name, legacy codes]
    // Legacy codes come from setup:install (base / default) and older versions of this script (uk_en).
    'pl' => ['Polska', 'main_website_store', 'Agrekom PL', 'pl_pl', 'Polski', ['base', 'default']],
    'uk' => ['United Kingdom', 'uk_store', 'Agrekom UK', 'en_gb', 'English', ['uk', 'uk_en']],
    'de' => ['Deutschland', 'de_store', 'Agrekom DE', 'de_de', 'Deutsch', ['de', 'de_de']],
];

$sort = 0;
foreach ($sites as $code => [$websiteName, $groupCode, $groupName, $storeCode, $storeName, [$legacyWebsite, $legacyStore]]) {
    $website = $om->create(Website::class)->load($code, 'code');
    if (!$website->getId()) {
        $website->load($legacyWebsite, 'code');
    }
    $website->setCode($code)->setName($websiteName)->setSortOrder($sort++)->save();

    $group = $om->create(Group::class)->load($groupCode, 'code');
    $group->setCode($groupCode)->setName($groupName)->setWebsiteId($website->getId())
        ->setRootCategoryId(2)->save();

    $store = $om->create(Store::class)->load($storeCode, 'code');
    if (!$store->getId()) {
        $store->load($legacyStore, 'code');
    }
    $store->setCode($storeCode)->setName($storeName)->setWebsiteId($website->getId())
        ->setGroupId($group->getId())->setIsActive(1)->setSortOrder(0)->save();

    $group->setDefaultStoreId($store->getId())->save();
    $website->setDefaultGroupId($group->getId())->save();
    echo "$code: website {$website->getId()}, group {$group->getId()}, store {$store->getId()} ($storeCode)\n";
}
