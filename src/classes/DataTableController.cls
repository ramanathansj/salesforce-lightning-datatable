/* @author Ram
 * @desc Simple controller class for datatable backend
 * Date 1/2/17
 */
public class DataTableController {
    
    @AuraEnabled
    public static ResultSet getSobjects(String columnfields, String objName, Integer currentPage, Integer lim, String sortField, String sortOrder, String whereCls) {
        ResultSet results = null;
        try {
        	List<String> fields =	splitQStr(columnfields);
            //get total rows
            String countQuery = 'Select count()'+' From '+objName;
            countQuery = String.isNotBlank(whereCls) ? countQuery + ' where '+whereCls : countQuery;
            System.debug(Logginglevel.info, 'countQuery ===== '+countQuery);
            Integer totalRows = Database.countQuery(countQuery+ ' LIMIT 50000');
            //get records
            String query = 'Select '+String.join(fields, ',')+' From '+ objName;
            query = String.isNotBlank(whereCls) ? query + ' where '+whereCls : query;
            query = query +' order by '+sortField+' '+sortOrder+' LIMIT '+lim +' Offset '+ currentPage;
            System.debug(Logginglevel.info, 'Full Query ===== '+query);
            List<sObject> sObjects = Database.query(query);
            //System.debug(Logginglevel.info, 'objects ===== '+sObjects);
            results =  processResults(fields, objName, sObjects, totalRows);    
        } catch (Exception ex) {
        	throw new DatatableException(' Error Occured! '+ex.getMessage());
        }
        return results;
    }
    
    private static ResultSet processResults(List<String> fields, String objName, List<sObject> sObjects, Integer totalRows) {
        List<Row> rows = new List<Row>();
        Map<String, Schema.DescribeFieldResult> fieldType = DataTableController.describeFields(objName);
        List<Cell> colNames = new List<Cell>();
        for (String fld : fields) {
            if (String.isEmpty(fld)) continue;
            fld = fld.trim().toLowerCase();
            //System.debug(logginglevel.info,'fld = '+fld);
            if (fld.containsAny('(') || fld.containsAny('((')) {
                fld = fld.substring(fld.lastIndexOfIgnoreCase('(')+1, fld.IndexOfIgnoreCase(')')).trim();
            	System.debug(logginglevel.info, 'formatted field == '+fld);
            }
            //System.debug(logginglevel.info,'fld = '+fld+', fieldType.get(fld) = '+fieldType.get(fld).getType().name());
            //System.debug(logginglevel.info,'fieldType.get(fld).getLabel = '+fieldType.get(fld));
            String flabel = fld.contains('.') ? getRelatedObjectFieldLabel(fld, fieldType) : fieldType.get(fld).getLabel();
            //System.debug(logginglevel.info,'fld = '+fld+ 'flabel == '+flabel+', fieldType.get(fld) = '+fieldType.get(fld).getType().name());
        	colNames.add(new Cell(fld, flabel, (!fld.contains('.') ? fieldType.get(fld).getType().name() : 'REFERENCE'), null, false));  
        }
        for(sObject temp : sObjects) {
            //Map<String, Object> obj = temp.getPopulatedFieldsAsMap();
            List<Cell> cols = new List<Cell>();
            for (String fld : fields) {
                fld = fld.trim().toLowerCase();
                Cell col;
                System.debug(logginglevel.info,'fld = '+fld+'fieldType.get(fld)= '+fieldType.get(fld));
                List<String> pickVals = new List<String>();
                if (fieldType.get(fld) !=null && fieldType.get(fld).getType().name().equalsIgnoreCase('picklist') && fieldType.get(fld) != null) pickVals = getPicklistValues(fieldType.get(fld).getPicklistValues());
                
                if (fld.containsAny('(') || fld.containsAny('((')) {
                	fld = fld.substring(fld.lastIndexOfIgnoreCase('(')+1, fld.IndexOfIgnoreCase(')')).trim();
            	}
                if (fld.contains('.')) {
                    Object fieldVal = getRelatedObjectFieldValue(fld, temp);
                	col = new Cell(fld, fieldVal,  'REFERENCE', pickVals, false); //update based object only in release one    
                } else if (temp.get(fld) != null){
                    col = new Cell(fld, temp.get(fld),  fieldType.get(fld).getType().name(), pickVals, fieldType.get(fld).isUpdateable());
                } else {
                    col = new Cell(fld, '',  fieldType.get(fld).getType().name(), pickVals, fieldType.get(fld).isUpdateable());
                }
                System.debug(logginglevel.info, 'data cell ==== '+col);
                cols.add(col);
            }
            rows.add(new Row(cols));
        }
        return new ResultSet(rows, totalRows, colNames, objName);
    }
    
    private static Map<String, Schema.DescribeFieldResult> describeFields(String objName) {
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{objName});
        Map<String, Schema.DescribeSObjectResult> childObjects = new Map<String, Schema.DescribeSObjectResult>();
        Map<String, Schema.DescribeFieldResult> fieldResults = new Map<String, Schema.DescribeFieldResult>();
        //describe object
        for(Schema.SObjectField field : results[0].fields.getMap().values()) {
        	Schema.DescribeFieldResult fResult = field.getDescribe();
            System.debug(logginglevel.info, 'fResult.getName() == '+fResult.getName().toLowerCase()+', fResult = '+fResult);
            fieldResults.put(fResult.getName().toLowerCase(), fResult);
        }
        return fieldResults;
    }
    
    private static String formatLookupFieldAPI(String ref, boolean flag) {
        String lookupApi = '';
        if (String.isNotBlank(ref)) {
            lookupApi = ref.trim().endsWithIgnoreCase('__r') ? ref.removeEndIgnoreCase('__r')+'__c' : ref.trim();//'Id'
        	lookupApi = flag && !lookupApi.endsWithIgnoreCase('__c') ? lookupApi+'id' : lookupApi;
        }
        return lookupApi;
    }
    
    private static Object getRelatedObjectFieldValue(String relationshipField, sObject resultObj) {
        Object result;
        if (String.isNotBlank(relationshipField) && resultObj != null) {
        	List<String> tempLevels = relationshipField.split('\\.');
            String findRelField = tempLevels[tempLevels.size()-1];
            tempLevels.remove(tempLevels.size()-1);
            for (Integer i=0; i<tempLevels.size(); i++) {
                if (resultObj != null)	resultObj = resultObj.getsObject(tempLevels[i]);
            }   
            result = resultObj != null ? resultObj.get(findRelField) : null;    
        }
        return result;
    }
    
    private static String getRelatedObjectFieldLabel(String relationshipField, Map<String, Schema.DescribeFieldResult> fieldResults) {
        List<String> tempLevels = relationshipField.split('\\.');
        String findRelField = tempLevels[tempLevels.size()-1];
        tempLevels.remove(tempLevels.size()-1);
        for (Integer i=0; i<tempLevels.size(); i++) {
        	String qualifiedAPIName = formatLookupFieldAPI(tempLevels[i], !tempLevels[i].endsWithIgnoreCase('__r'));
            System.debug(logginglevel.info, 'qualifiedAPIName  == '+qualifiedAPIName);
            Schema.SObjectType childRel =	descRelationShips(tempLevels[i], fieldResults.get(qualifiedAPIName));
            fieldResults = describeFields(childRel.getDescribe().getName());
        }
        String fieldLabel;
        if (fieldResults != null ) {
        	for(Schema.DescribeFieldResult fResult : fieldResults.values()) {
                if (fResult.getName().equalsIgnoreCase(findRelField) ) {
                	fieldLabel = fResult.getLabel();
                    break;
                }
            }
        }
        System.debug(logginglevel.info, 'fieldLabel final value  == '+fieldLabel);
        return fieldLabel;
    }
    
    private static Schema.SObjectType descRelationShips(String relationshipField, Schema.DescribeFieldResult objResult) {
        List<Schema.sObjectType> returnObj = objResult.getReferenceTo();
        return returnObj != null && returnObj.size() > 0 ? returnObj[0] : null;
    }
    
    private static List<String> splitQStr(String flds) {
        Set<String> fields = new Set<String>();
        boolean idFound = false;
        if (String.isNotBlank(flds)) {
            for (String fld : flds.split(',')) {
                if (String.isNotBlank(fld)) {
                	fields.add(fld.trim());
                    if (fld.trim().equalsIgnoreCase('id')) idFound = true;
                }
            }    
        }
        if (!idFound) fields.add('Id');
        return new List<String>(fields);
    }
    
    private static List<String> getPicklistValues(List<Schema.PicklistEntry> pickEntries) {
        List<String> pickVals = new List<String>();
        for (Schema.PicklistEntry pick : pickEntries) {
        	pickVals.add(pick.getValue());    
        }
        return pickVals;
    }
    
    @AuraEnabled
    public static String bulkSaveRecords(String rowJSON, String obName) {
        System.debug(logginglevel.info , 'rows ======= '+rowJSON);
        List<Object> rows = (List<Object>) JSON.deserializeUntyped(rowJSON);
        List<sObject> sObjectsToUpdate = new List<sObject>();
        for (Object temp : rows) {
            Map<String, Object> objVal = (Map<String, Object>) temp;
            for (String key : objVal.keySet()) {
                List<Object> objVal2 = (List<Object>) objVal.get(key);
                sObject objRecord = Schema.getGlobalDescribe().get(obName).newSObject();
                for (Object row : objVal2) {
                    Map<String, Object> obMap = (Map<String, Object>) row;
                    //System.debug('object '+obMap);
                    try {
                    	parseFieldValues(obMap, objRecord);    
                    } catch (Exception ex) {
                        throw new DatatableException(' Error Occured! '+ex.getMessage());
                    }
                }
                if (objRecord.get('id') != null ) sObjectsToUpdate.add(objRecord);
                System.debug('sobject  ============== '+objRecord);
            }
        }
        System.debug('sObjectsToUpdate  ============== '+sObjectsToUpdate);
        Database.SaveResult[] results = new List<Database.SaveResult>();
        results = Database.update(sObjectsToUpdate, true);
        return JSON.serialize(results); 
    }
    
    private static void parseFieldValues(Map<String, Object> obMap, sObject objRecord) {
    	if ((Boolean.valueOf(obMap.get('isWritable')) || String.valueOf(obMap.get('fieldApi')).equalsIgnoreCase('Id')) && String.isNotBlank(String.valueOf(obMap.get('fieldValue')))) {
        	String dataType = String.Valueof(obMap.get('fieldType'));
            //System.debug('dataType === '+dataType);
            if (dataType.equalsIgnoreCase('Currency') || dataType.equalsIgnoreCase('Percent')) {
            	objRecord.put(String.Valueof(obMap.get('fieldApi')), Decimal.valueOf(String.valueOf(obMap.get('fieldValue'))));
            } 
            else if (dataType.equalsIgnoreCase('Date')) {
            	objRecord.put(String.Valueof(obMap.get('fieldApi')), Date.valueOf(String.ValueOf(obMap.get('fieldValue'))));
            }
            else if (dataType.equalsIgnoreCase('DateTime')) {
            	System.debug(logginglevel.INFO, obMap.get('fieldApi')+'datetime before === '+obMap.get('fieldValue'));
                Datetime dt = (Datetime)JSON.deserialize(String.valueOf(obMap.get('fieldValue')).trim(), Datetime.class);
                //Datetime dt = Datetime.valueOf(String.valueOf(obMap.get('fieldValue')).replace('T', ' ').replace('Z', '').trim());
                System.debug(logginglevel.INFO,'datetime after === '+dt);
                objRecord.put(String.Valueof(obMap.get('fieldApi')), dt);
            }
            else if (dataType.equalsIgnoreCase('Double')){
            	objRecord.put(String.Valueof(obMap.get('fieldApi')), Double.valueOf(obMap.get('fieldValue')));
            }
            else if (dataType.equalsIgnoreCase('Integer')){
            	objRecord.put(String.Valueof(obMap.get('fieldApi')), Integer.valueOf(obMap.get('fieldValue')));
            }
            else {
            	objRecord.put(String.Valueof(obMap.get('fieldApi')), obMap.get('fieldValue'));    
            }   
       }  
    }
    
    
    public class Cell {
  		@AuraEnabled public String fieldApi {get; set;}
        @AuraEnabled public String fieldType {get; set;}
        @AuraEnabled public Object fieldValue {get; set;}
        @AuraEnabled public Long unixTime {get; set;}
        @AuraEnabled public Decimal currencyVal {get; set;}
        @AuraEnabled public List<String> pickValues {get; set;}
        @AuraEnabled public boolean isWritable {get; set;}
        
        
        public Cell (String fApi, Object fVal, String fType, List<String> pickVal, boolean readOnly) {
        	this.fieldApi = fApi;
            this.fieldType = fType;
            this.fieldValue = fVal;
            this.isWritable = readOnly;
            this.pickValues = pickVal;
            if (fType.equalsIgnoreCase('datetime') && this.fieldValue instanceof Datetime && this.fieldValue !=null) {
            	//System.debug(logginglevel.info, 'fieldValue ==== '+fieldValue);
                Datetime temp = Datetime.valueOf(this.fieldValue);
                this.unixTime =	temp.getTime();
            }
            if (fType.equalsIgnoreCase('currency') && this.fieldValue instanceof Decimal && this.fieldValue !=null) {
            	///System.debug(logginglevel.info, 'fieldValue ==== '+fieldValue);
                this.currencyVal = (Decimal)this.fieldValue;
            }
        }
    }
    
    public class Row {
        @AuraEnabled public List<Cell> fields {get; set;}
        
        public Row(List<Cell> cols) {
            this.fields = cols;
        }
    }
   
    public class ResultSet {
        @AuraEnabled public List<Row> rows {get; set;}
        @AuraEnabled public Integer size {get; set;}
        @AuraEnabled public List<Cell> columnHeader {get; set;}
        
        public ResultSet(List<Row> rw, Integer siz, List<Cell> ch, String obName) {
        	this.rows = rw;
            this.size = siz;
            this.columnHeader = ch;
        }
    }
    
    public class DatatableException extends Exception { }

}