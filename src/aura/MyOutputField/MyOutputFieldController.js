({
	click : function(component, event, helper) {
		var clickEvt = $A.get("e.c:MyOutputClickEvt");
        clickEvt.setParams({ "fieldid":component.get("v.recordid")});
        clickEvt.fire();
	}
})