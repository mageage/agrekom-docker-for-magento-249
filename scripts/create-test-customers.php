<?php
// Creates one test customer per website (customer accounts are per website), with a default address.
// Idempotent. Run: docker compose exec -T php php < scripts/create-test-customers.php
// Login: test.<website code>@example.test / Test1234!  (local test data only)
use Magento\Customer\Api\AccountManagementInterface;
use Magento\Customer\Api\CustomerRepositoryInterface;
use Magento\Customer\Api\Data\AddressInterfaceFactory;
use Magento\Customer\Api\Data\CustomerInterfaceFactory;
use Magento\Framework\App\Bootstrap;
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Store\Model\StoreManagerInterface;

require '/var/www/html/app/bootstrap.php';
$om = Bootstrap::create(BP, $_SERVER)->getObjectManager();
$om->get(\Magento\Framework\App\State::class)->setAreaCode('frontend');

const PASSWORD = 'Test1234!';
$customers = [
    // website code => [firstname, lastname, country, city, postcode, street, phone]
    'pl'        => ['Jan', 'Testowy', 'PL', 'Warszawa', '00-001', 'Testowa 1', '+48 500 000 001'],
    'de'        => ['Hans', 'Test', 'DE', 'Berlin', '10115', 'Teststraße 1', '+49 30 0000001'],
    'uk'        => ['John', 'Test', 'GB', 'London', 'SW1A 1AA', '1 Test Street', '+44 20 0000 0001'],
    'ewarsztat' => ['Anna', 'Testowa', 'PL', 'Kraków', '30-001', 'Próbna 2', '+48 500 000 002'],
];

$storeManager = $om->get(StoreManagerInterface::class);
$repository = $om->get(CustomerRepositoryInterface::class);
$regions = $om->get(\Magento\Directory\Model\ResourceModel\Region\CollectionFactory::class);

foreach ($customers as $websiteCode => [$first, $last, $country, $city, $postcode, $street, $phone]) {
    try {
        $website = $storeManager->getWebsite($websiteCode);
    } catch (\Exception $e) {
        echo "$websiteCode: website not found - skipped\n";
        continue;
    }
    $store = $storeManager->getGroup($website->getDefaultGroupId())->getDefaultStore();
    $email = "test.$websiteCode@example.test";
    try {
        $repository->get($email, $website->getId());
        echo "$websiteCode: $email already exists\n";
        continue;
    } catch (NoSuchEntityException $e) {
    }
    $storeManager->setCurrentStore($store->getId());

    $address = $om->get(AddressInterfaceFactory::class)->create()
        ->setFirstname($first)->setLastname($last)->setCountryId($country)->setCity($city)
        ->setPostcode($postcode)->setStreet([$street])->setTelephone($phone)
        ->setIsDefaultBilling(true)->setIsDefaultShipping(true);
    $region = $regions->create()->addCountryFilter($country)->getFirstItem();
    if ($region->getId()) {
        $address->setRegionId($region->getId());
    }

    $customer = $om->get(CustomerInterfaceFactory::class)->create()
        ->setWebsiteId($website->getId())->setStoreId($store->getId())->setGroupId(1)
        ->setFirstname($first)->setLastname($last)->setEmail($email)->setAddresses([$address]);

    // createAccount() also sends the welcome e-mail (Mailpit locally)
    $saved = $om->get(AccountManagementInterface::class)->createAccount($customer, PASSWORD);
    echo "$websiteCode: created $email (customer {$saved->getId()}, store {$store->getCode()})\n";
}
