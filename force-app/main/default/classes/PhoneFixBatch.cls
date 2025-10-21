public class PhoneFixBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String recordType; // 'Lead' or 'Contact'

    // Constructor
    public PhoneFixBatch(String recordType) {
        this.recordType = recordType;
    }

    // --------------------------
    // Start Method
    // --------------------------
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query;

        if (recordType == 'Lead') {
            query = 'SELECT Id, MobilePhone FROM Lead WHERE MobilePhone != null';
        } else if (recordType == 'Contact') {
            query = 'SELECT Id, MobilePhone FROM Contact WHERE MobilePhone != null';
        }

        return Database.getQueryLocator(query);
    }

    // --------------------------
    // Execute Method
    // --------------------------
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<sObject> recordsToUpdate = new List<sObject>();

        for (sObject sObj : scope) {
            String originalPhone = (String)sObj.get('MobilePhone');
            String cleanedPhone = cleanPhone(originalPhone);

            if (cleanedPhone == null) continue;

            // Format phone only if valid Israeli number
            String formattedPhone = formatIfIsraeli(cleanedPhone);

            if (formattedPhone != null && formattedPhone != originalPhone) {
                sObj.put('MobilePhone', formattedPhone);
                recordsToUpdate.add(sObj);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    // --------------------------
    // Finish Method
    // --------------------------
    public void finish(Database.BatchableContext BC) {
        System.debug('[' + recordType + '] MobilePhone fix batch finished.');
    }

    // --------------------------
    // Helper Methods
    // --------------------------

    // Removes all non-numeric characters except '+' for detection
    private String cleanPhone(String phone) {
        if (String.isBlank(phone)) return null;
        return phone.replaceAll('[^0-9+]', ''); // keep only digits and plus
    }

    // Validates & formats Israeli mobile numbers
    private String formatIfIsraeli(String phone) {
        if (String.isBlank(phone)) return null;

        // Normalize input
        phone = phone.trim();

        // Case 1: Starts with +972
        if (phone.startsWith('+972')) {
            phone = phone.replace('+972', '972');
        }

        // Case 2: Starts with 972
        if (phone.startsWith('972')) {
            phone = phone.substring(3);
            if (phone.startsWith('0')) phone = phone.substring(1);
        }
        // Case 3: Starts with 0
        else if (phone.startsWith('0')) {
            phone = phone.substring(1);
        }

        // Now should start with 5XXXXXXXX (9 digits)
        if (!phone.startsWith('5')) return null; // not an Israeli mobile prefix
        if (phone.length() != 9) return null; // mobile should be exactly 9 digits after 5

        // Check if all numeric
        if (!Pattern.matches('^[0-9]+$', phone)) return null;

        // Final formatted version
        return '+972' + phone;
    }
}