({
	queryRows : function(component, page, sOrder) {
        var action = component.get("c.getSobjects");
        //console.log("=== fields ===="+fields);
		var params = { "columnfields": component.get("v.columnfields"), "objName": component.get("v.object"), "currentPage": page, "lim": component.get("v.pagelimit") || 10
                      ,"sortField" : component.get("v.sortField"), "sortOrder" :  sOrder || "asc" , "whereCls":component.get("v.whereclause") };
        console.log(JSON.stringify(params));
        action.setParams(params);
        action.setCallback(this, function(response) {
            console.log(response.getState());
            if (response && response.getState() === "SUCCESS" && component.isValid()) {
            	var recordset = response.getReturnValue();
                if (component.get("v.columns").length <= 0) {
                	component.set("v.columns", recordset.columnHeader);   
                }
                console.log(recordset.rows);
                component.set("v.results", recordset.rows);
                component.set("v.resultsetsize", recordset.size);
            }
        });
        $A.enqueueAction(action);
	},
    getSortOrder : function(cmp, changeorder) {
        if (changeorder && changeorder === true) {
        	if (cmp.get("v.ascDescVal") === "asc") {
                cmp.set("v.ascDescVal", "desc");
            } else if (cmp.get("v.ascDescVal") === "desc") {
                cmp.set("v.ascDescVal", "asc");
            } else {
                cmp.set("v.ascDescVal", "desc");
            }    
        }
        return cmp.get("v.ascDescVal");
	},
    bulkSaveRecords: function(component, event, helper) {
		var action = component.get("c.bulkSaveRecords");
        var records = component.get("v.results");
        for (var i=0; i< records.length; i+=1) {
            console.log("record = "+JSON.stringify(records[i]));
        }
        action.setParams({"rowJSON":JSON.stringify(records), "obName":component.get("v.object")});
        action.setCallback(this, function(response) {
        	if (response && response.getState() === "SUCCESS") {
            	//console.log("bulksave resp = "+response.getReturnValue());
                var resultRsp = JSON.parse(response.getReturnValue());
                var erroroccured = false;
                for (var i=0; i<resultRsp.length; i+=1) {
                    if (resultRsp[i].success !== true || resultRsp[i].errors.length > 0) {
                    	erroroccured = true;    
                    }
                }
                //console.log("resultRsp == "+JSON.stringify(resultRsp));
                if (!erroroccured) {
                	component.set("v.messages", "Record Saved Successfully");
                	component.set("v.status", "success");     
                } else if (erroroccured === true) {
                    component.set("v.messages", "Error Occurred! Contact Your Administrator or Check Console Logs!");
                    component.set("v.status", "fail");
                }
            }
         });
        $A.enqueueAction(action);
	}
})