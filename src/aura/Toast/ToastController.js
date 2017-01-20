({
	destory : function(component, event, helper) {
        console.log("timeouts = "+component.get("v.timeoutMS"));
        if (component.get("v.message") && component.get("v.message").length > 0) {
        	window.setTimeout(
                $A.getCallback(function() {
                    if (component.isValid()) {
                        component.set("v.message", "");
                    }
                }), component.get("v.timeoutMS")
            );    
        } 	
	}
})