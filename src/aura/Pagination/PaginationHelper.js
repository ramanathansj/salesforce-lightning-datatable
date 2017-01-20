({
    removeBtnCSS: function(component) {
    	$A.util.removeClass(component.find('first'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('previous'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('next'),'uiButton--default uiButton');
        $A.util.removeClass(component.find('last'),'uiButton--default uiButton');
    },
    
    pageRecords : function(component, event, helper, flag) {
        var buttonval = "";
        if (flag === true) {
            buttonval = "first";
        } else {
        	buttonval = event.getSource().getLocalId().toLowerCase();    
        }
        console.log("buttonval = "+buttonval);
        if (buttonval) {
            var pagelimit = component.get("v.pagelimit"), offsetvalue = component.get("v.offset"), 
                totalrows = component.get("v.resultsetsize");
            //console.log("resultsetsize = "+totalrows);
            if (buttonval === "first") {
                offsetvalue = 0;
                component.set("v.isLast", false);
            } else if (buttonval === "previous") {
                offsetvalue = (offsetvalue - pagelimit) * 1;
                component.set("v.isLast", false);
            } 
            else if (buttonval === "last" || buttonval === "next") {
                if (totalrows > (offsetvalue + pagelimit) && buttonval === "next") {
                    offsetvalue = (offsetvalue + pagelimit) * 1;
                    component.set("v.isLast", false);
                }
                if (buttonval === "last" || totalrows <= (offsetvalue + pagelimit) ) {
                	var currentpage = (totalrows % pagelimit) > 0 ? Math.floor(totalrows / pagelimit) + 1  : Math.floor(totalrows / pagelimit);
                    //console.log("last page = "+currentpage);
                    offsetvalue =  (currentpage - 1) * pagelimit * 1;
                    component.set("v.isLast", true);
                }
            }
            //console.log("offsetvalue = "+offsetvalue);
            component.set("v.offset", offsetvalue);
            var pageEvt = $A.get("e.c:PaginationEvent");
            pageEvt.setParams({ "pagevalue":offsetvalue});
        	pageEvt.fire();
        }    
    }
})