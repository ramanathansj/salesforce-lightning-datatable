<aura:application extends="force:slds">
	<ltng:require styles="/resource/testram__SLDS24/assets/styles/salesforce-lightning-design-system.min.css"/>
	
    <div class="slds" style="padding:10px">
        
        <!-- initiate opportunity table with accounts join -->
        <c:DataTableV2 columnfields="Id, Name, LeadSource, Amount, CloseDate, Description, Account.Owner.Name" 
                       object="Opportunity"  
                       whereclause="accountId IN (Select Id From Account where Type IN ('Customer - Direct', 'Customer - Channel'))" 
                       pagelimit="10" sortField="Name"/>
        
        
    </div>
</aura:application>