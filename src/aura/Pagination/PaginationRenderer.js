({
	// Your renderer method overrides go here
	afterRender: function (component, helper) {
        if (component.isValid()) {
        	this.superAfterRender();
        	helper.removeBtnCSS(component);    
        }
              
    }
})