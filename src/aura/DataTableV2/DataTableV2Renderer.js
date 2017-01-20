({
	afterRender: function (component, helper) {
    	this.superAfterRender();
    	console.log("after rerender completed");
	},
    unrender: function (component, helper) {
    	this.superUnrender();
        console.log("unrender completed");
    	// do custom unrendering here
	},
    rerender : function(component, helper){
    	this.superRerender();
        console.log("rerender completed");
	},
    render : function(component, helper) {
    	var ret = this.superRender();
    	// do custom rendering here
    	console.log("render completed");
    	return ret;
	}
})