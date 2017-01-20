({
	doInit: function(cmp,event,helper) {
        if (cmp.isValid()) {
        	//helper.queryFieldsFomrat(cmp);
        	var whereCls = cmp.get("v.whereclause");
            if (cmp.get("v.isRelatedList") === true && whereCls && whereCls.trim().length > 0) {
                whereCls = whereCls.toLowerCase().replace('{recordid}', '\''+cmp.get("v.recordId")+'\'');
                cmp.set("v.whereclause", whereCls);
            }
            helper.queryRows(cmp, 0, helper.getSortOrder(cmp, false));
        }
	},    
    pagerecords : function (cmp,event,helper) {
        if (cmp.isValid()) {
            cmp.set("v.page", event.getParam("pagevalue"));
            helper.queryRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, false));
        }
    },
    customSort : function(cmp,event,helper) {
        if (cmp.isValid()) {
        	cmp.set("v.sortField", event.getParam("fieldid"));
            cmp.set("v.page", event.getParam("pagevalue"));
            helper.queryRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true));
        }
    },
    showSpinner : function (component, event, helper) {
        if (component.isValid()) component.set("v.showspinner", true); 
    },
    hideSpinner : function (component, event, helper) {
       if (component.isValid()) component.set("v.showspinner", false);
    },
    showEdit : function (component, event, helper) {
        try {
            if (component.isValid()) {
                component.set("v.edit", 1);
                helper.queryRows(component, component.get("v.page") || 0, helper.getSortOrder(component, false));        
            }
        } catch (e) {
            console.log("mode == "+e);
        	throw new Error("error occured refresh page!!"+e);    
        }
    },
    cancelEdit : function (component, event, helper) {
        try {
            if (component.isValid()) {
                component.set("v.edit", 0);
                helper.queryRows(component, component.get("v.page") || 0, helper.getSortOrder(component, false));	
            } 
        } catch (e) {
            console.log("mode == "+e);
           	throw new Error("error occured refresh page!!");
        }
    },
    saveRecords : function (component, event, helper) {
        helper.bulkSaveRecords(component, event, helper);
    }
})