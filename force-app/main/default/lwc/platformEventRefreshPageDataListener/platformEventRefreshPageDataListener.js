// @ts-check
import { api, LightningElement } from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import currentUserId from "@salesforce/user/Id";

export default class platformEventRefreshPageDataListener extends LightningElement {
    @api recordId;
    channelName = "/event/Refresh_Page_Data__e";
    subscription = {};

    connectedCallback() {
        const refreshCallback = (response) => {
            const eventData = this.checkForNameSpace(response["data"]["payload"]);

            const eventDetails = this.cloneObject({
                recordId: this.recordId,
                currentUserId: currentUserId,
                eventRecordId: eventData["RecordId__c"],
                eventCreatedById: eventData["CreatedById"]
            });

            console.debug("Refresh event received", eventDetails);

            if (!eventData) {
                console.debug("No event data", eventData);
                return;
            }

            const isEventCreatedByCurrentUser = eventData["CreatedById"] == currentUserId;
            if (!isEventCreatedByCurrentUser) {
                console.debug("Event not created by current user, ignoring it");
                return;
            }

            const isEventForThisRecord = eventData["RecordId__c"] == this.recordId;
            if (!isEventForThisRecord) {
                console.debug("Event not for this record, ignoring it");
                return;
            }

            this.refreshPageData();
        };

        subscribe(this.channelName, -1, refreshCallback).then((response) => {
            console.debug(
                `Subscribed to Refresh_Page_Data__e channel, listening for record: ${this.recordId}, user: ${currentUserId}`
            );
            this.subscription = response;
        });
        onError((error) => {
            this.waitDebug("Error in platform event refresh page data: " + this.cloneObject(error), 3000);
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.debug("Unsubscribed from Refresh_Page_Data__e channel");
        });
    }

    checkForNameSpace(eventRecord) {
        let newEventRecord = {};
        for (let key in eventRecord) {
            if (key.includes("RecordId__c")) {
                newEventRecord["RecordId__c"] = eventRecord[key];
            } else {
                newEventRecord[key] = eventRecord[key];
            }
        }
        return newEventRecord;
    }

    refreshPageData() {
        // eval("$A.get('e.force:refreshView').fire();"); // Does not work in all environments / some versions of Lightning Locker
        this.dispatchEvent(new CustomEvent("refreshpagedata"));
        console.debug("Refreshed page data");
    }

    /**
     * Only debugs once every waitTimeMs
     * Used in order to prevent spamming the console, which could cause performance issues
     */
    waitDebug = (function () {
        let lastLogTime = 0;
        return function (message, waitTimeMs = 1000) {
            const now = Date.now();
            if (now - lastLogTime > waitTimeMs) {
                console.debug(message);
                lastLogTime = now;
            }
        };
    })();

    /**
     * Rebuilds an object to remove any references to the original object
     * This allows logging the object, without lightning locker locking it
     */
    cloneObject(obj) {
        return JSON.parse(JSON.stringify(obj));
    }
}