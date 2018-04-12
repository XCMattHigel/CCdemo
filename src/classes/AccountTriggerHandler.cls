public with sharing class AccountTriggerHandler {

    public static Map<String, String> fieldSyncMap {
        get {
            return new Map<String, String>{
                    'BillingStreet' => 'MailingStreet',
                    'BillingCity' => 'MailingCity',
                    'BillingState' => 'MailingState',
                    'BillingPostalCode' => 'MailingPostalCode',
                    'Phone' => 'Phone'
            };
        }
    }

    public static void onAfterUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        Map<Id, Account> accountAddressChangedMap = new Map<Id, Account>();
        for (String diffField : fieldSyncMap.keySet()) {
            String newMapJson = JSON.serialize(newMap);
            String oldMapJson = JSON.serialize(oldMap);
            for (Account a : (List<Account>) TriggerUtility.getDiffSObjectList(newMapJson, oldMapJson, diffField)) {
                accountAddressChangedMap.put(a.Id, a);
            }
        }

        if (!accountAddressChangedMap.isEmpty()) {
            syncAccountContactAddresses(accountAddressChangedMap);
        }
    }

    static void syncAccountContactAddresses(Map<Id, Account> accountAddressChangedMap) {
        List<String> aIdList = new List<String>();
        for(Id aId : accountAddressChangedMap.keySet()) {
            aIdList.add(String.valueOf(aId));
        }
        String aIdListStr = '(\'' + String.join(aIdList, '\', \'') + '\')';
        String q = 'SELECT Id, AccountId, ' + String.join(fieldSyncMap.values(), ', ') +
                ' FROM Contact WHERE AccountId IN ' + aIdListStr;
        List<Contact> contactList = (List<Contact>) Database.query(q);

        for (Contact c : contactList) {
            Account a = accountAddressChangedMap.get(c.AccountId);

            for (String aField : fieldSyncMap.keySet()) {
                String cField = fieldSyncMap.get(aField);
                c.put(cField, a.get(aField));
            }
        }

        update contactList;
    }

}