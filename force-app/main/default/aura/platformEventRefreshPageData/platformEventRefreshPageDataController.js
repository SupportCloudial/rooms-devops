({
    handleRefreshPageData : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    recordId : function() {
        return this.get('v.recordId');
    }
})