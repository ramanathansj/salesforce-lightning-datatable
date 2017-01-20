({
	paginate : function(component, event, helper) {
    	if (component.isValid()) helper.pageRecords(component, event, helper);    
	},
    doneRerender : function (component, event, helper) {
    	if (component.isValid()) helper.removeBtnCSS(component);
    },
	changepage : function (component, event, helper) {
    	if (component.isValid()) {   
            var selectcmp = component.find('selectpageid');
            var pagelimit = parseInt(selectcmp.getElement().value, 10);
            if (pagelimit) {
                component.set("v.pagelimit", pagelimit);
                helper.pageRecords(component, event, helper, true);
            }
            //console.log(selectcmp.getElement().value );
        }
    }    
})