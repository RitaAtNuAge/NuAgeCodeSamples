public with sharing class ClientHierarchyController {
/**  Copyright (c) 2008, Matthew Friend, Sales Engineering, Salesforce.com Inc.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
*  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
*  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
*  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
*  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
*  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
* To adapt this to anouther Object simply search for "Change" to go to the places 
* where the sObject and query must be changed
*/
/* NuAge Experts 3/24/2018 - adapted for Lightning:Tree */
//public with sharing class AccountStructure{

    //Declare variables
    public String currentId;
    public List<ObjectStructureMap> asm ;
    public Map<String, ObjectStructureMap> masm;
    public List<Integer> maxLevel;
    
    /**
    * Contructor
    */
    @AuraEnabled  
    public static List<items> getAccountHierarchy(Id accountId) { 
    	List<items> finalWrp = new List<items>();
    	finalWrp = getObjectStructure(finalWrp, accountId);
    	return finalWrp;
    }
    
    /**
    * Allow page to set the current ID
    */
    public void setcurrentId( String cid ){
        currentId = cid;
    }

    /**
    * Return ObjectStructureMap to page
    * @return asm
    */
    public static List<items> getObjectStructure(List<items> finalWrp, String currentId){
    	if ( currentId == null ) {
            currentId = System.currentPageReference().getParameters().get( 'id' );
        }
        
        finalWrp = formatObjectStructure( finalWrp, CurrentId );
        List<ObjectStructureMap> gothroughlist = new List<ObjectStructureMap>();
        
        return finalWrp;
    }

    /**
    * Query Account from top down to build the ObjectStructureMap
    * @param currentId
    * @return asm
    */
    public static List<items> formatObjectStructure(List<items> finalWrp, String currentId ){
    
        List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
        Map<String, ObjectStructureMap> masm = new Map<String, ObjectStructureMap>();
        masm.clear();
        List<Integer> maxLevel = new List<Integer>();

        //Change below
        List<Account> al            = new List<Account>{};
        List<ID> currentParent      = new List<ID>{};
        Map<ID, String> nodeList    = new Map<ID, String>{};
        List<String> nodeSortList   = new List<String>{};
        List<Boolean> levelFlag     = new List<Boolean>{};
        List<Boolean> closeFlag     = new List<Boolean>{};
        String nodeId               = '0';
        String nodeType             = 'child';
        Integer count               = 0;
        Integer level               = 0;
        Boolean endOfStructure      = false;
        List<nodeListItem> nodeLst = new List<nodeListItem>();
        //Find highest level obejct in the structure
        currentParent.add( GetTopElement( currentId ) );
        
        //Loop though all children
        while ( !endOfStructure ){

            if( level == 0 ){
                //Change below     
                al = [ SELECT a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.id IN : CurrentParent ORDER BY a.Name desc ];
            } 
            else {
                //Change below      
                al = [ SELECT a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.ParentID IN : CurrentParent ORDER BY a.Name desc];
            }

            if( al.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                for ( Integer i = 0 ; i < al.size(); i++ ){
                    //Change below
                    Account a = al[i];
                    nodeId = ( level > 0 ) ? NodeList.get( a.ParentId )+'.'+String.valueOf( i ) : String.valueOf( i );
                    masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
                    currentParent.add( a.id );
                    nodeList.put( a.id,nodeId );
                    nodeSortList.add( nodeId );
                    nodeListItem nl = new nodeListItem();
                    nl.nodeId = nodeId;
                    nl.accountId = a.id;
                    nodeLst.add(nl);
                }
                
                maxLevel.add( level );                
                level++;
            }
        }
        
        //Account structure must now be formatted
        NodeSortList.sort();
        for( Integer i = 0; i < NodeSortList.size(); i++ ){
            List<String> pnl = new List<String> {};
            List<String> cnl = new List<String> {};
            List<String> nnl = new List<String> {};
            
            if ( i > 0 ){
                String pn 	= NodeSortList[i-1];
                pnl 		= pn.split( '\\.', -1 );
            }

            String cn 	= NodeSortList[i];
            cnl 		= cn.split( '\\.', -1 );

            if( i < NodeSortList.size()-1 ){
                String nn = NodeSortList[i+1];
                nnl = nn.split( '\\.', -1 );
            }
            
            ObjectStructureMap tasm = masm.get( cn );
            if ( cnl.size() < nnl.size() ){
                //Parent
                tasm.nodeType = ( isLastNode( cnl, masm ) ) ? 'parent_end' : 'parent';
            }
            else if( cnl.size() > nnl.size() ){
                tasm.nodeType 	= 'child_end';
                tasm.closeFlag 	= setcloseFlag( cnl, nnl, tasm.nodeType );
            }
            else{
                tasm.nodeType = 'child';
            }
            
            tasm.levelFlag = setlevelFlag( cnl, tasm.nodeType, masm ); 
            
            //Change below
            if ( tasm.account.id == currentId ) {
                tasm.currentNode = true;
            }
            asm.add( tasm );
        }
        
        asm[0].nodeType 			= 'start';
        asm[asm.size()-1].nodeType 	= 'end';
        
        //Create map of children Ids and their parent Id;  this is used to 
        //direct the rollup from children to parents
        Map<String, String> childParent = new Map<String, String>();
        for(ObjectStructureMap os : asm){
        	if(os.account.ParentId == null){
        		childParent.put(os.account.Id, 'start');
        	}
        	else{
        		childParent.put(os.account.Id, os.account.ParentId);
        	}
        }
        //Create map that will be the start of the Lightning:tree structure
        //This will be a map of parent Ids with their child items.
        Map<String, List<items>> nodeMap = new Map<String, List<items>>();
        Map<String, String> parentMap = new Map<String, String>();
        List<items> nodeItems = new List<items>();
        List<items> parentItems = new List<items>();
        List<items> grandParentItems = new List<items>();
        
        items nodeItem;
        String parentId = '';
        Integer J=asm.size() - 1;
        while(asm.size() > 0){
        	ObjectStructureMap asmEntry = asm[j];
        	nodeItems = new List<items>();
        	nodeItem = new items(asmEntry.account.Type, '/lightning/r/Account/' + asmEntry.account.Id + '/view', 
   				asmEntry.account.Name + ', ' + asmEntry.account.Type, true, null);
   			if(asmEntry.account.ParentId == null){
   				parentId = 'start';
   			}
   			else{
   				parentId = asmEntry.account.ParentId;
   			}
   			if(nodeMap.get(parentId) == null){
   				nodeItems.add(nodeItem);
   				nodeMap.put(parentId, nodeItems);
   			}
   			else{
   				nodeItems = nodeMap.get(parentId);	
   				nodeItems.add(nodeItem);
   				nodeMap.put(parentId, nodeItems);
   			}
   			asm.remove(j);
   			j--;
        }
        //Now that we have the first parent/children map, iterate until it is rolled up
        for(Integer k = nodeLst.size() - 1; k > 0; k--){
        	nodeListItem nlst = nodeLst[k];
        	String currentKey = nlst.accountId;
        	String parent = childParent.get(currentKey);
        	String grandParent = childParent.get(parent);
        	parentItems = new List<items>();
        	grandParentItems = new List<items>();
        	parentItems = nodeMap.get(parent);
        	grandParentItems = nodeMap.get(grandParent);	
        	if(parentItems == null || grandParentItems == null){
        		continue;
        	}
        	for(items gpItems :grandParentItems){
				//Change below - if your object name changes, the substring to pick up the id will shift
            	//system.debug('gpItems.href.substring(21, 39) ' + gpItems.href.substring(21, 39));
            	if(parent == gpItems.href.substring(21, 39)){
					gpItems.items = new List<items>(parentItems);
				}
			}        	
			nodeMap.put(grandParent, grandParentItems);
			nodeMap.remove(parent);
        }
        return finalWrp = nodeMap.get('start');
    }
    
    /**
    * Determin parent elements relationship to current element
    * @return flagList
    */
    public static List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType,  Map<String, ObjectStructureMap> masm ){
    	
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode 	= '';
        String workNode 	= '';
        Integer cn 			= 0;
        
        for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
            cn = Integer.valueOf( nodeElements[i] );
            cn++;
            searchNode 	= workNode + String.valueOf( cn );
            workNode 	= workNode + nodeElements[i] + '.';
            if ( masm.containsKey( searchNode ) ){
                flagList.add( true );
            }
            else {
                flagList.add( false );
            }
        }
        
        return flagList;
    }
    
    /**
    * Determin if the element is a closing element
    * @return flagList
    */
    public static List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
    	
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode 	= '';
        String workNode 	= '';
        Integer cn 			= 0;
        
        for( Integer i = nnl.size(); i < cnl.size(); i++ ){
        	flagList.add( true );
        }
        
        return flagList;
    }
    
    /**
    * Determin if Element is the bottom node  
    * @return Boolean
    */
    public static Boolean isLastNode( List<String> nodeElements,  Map<String, ObjectStructureMap> masm){
    	
        String searchNode 	= '';
        Integer cn 			= 0;
        
        for( Integer i = 0; i < nodeElements.size(); i++ ){
            if ( i == nodeElements.size()-1 ){
                cn = Integer.valueOf( nodeElements[i] );
                cn++;
                searchNode = searchNode + String.valueOf( cn );
            }
            else {
                searchNode = searchNode + nodeElements[i] + '.';
            }
        }
        if ( masm.containsKey( searchNode ) ){
            return false;
        }
        else{
            return true;
        }
    }
    
    /**
    * Find the tom most element in Heirarchy  
    * @return objId
    */
    public static String GetTopElement( String objId ){
    	
        Boolean top = false;
        while ( !top ) {
            //Change below
            Account a = [ Select a.Id, a.ParentId From Account a where a.Id =: objId limit 1 ];
            
            if ( a.ParentID != null ) {
                objId = a.ParentID;
            }
            else {
                top = true;
            }
        }
        return objId ;
    }
    
	/**
    * Wrapper class
    */
    public with sharing class ObjectStructureMap{

        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        
        /**
        * @Change this to your sObject
        */
        public Account account;
        
        public String getnodeId() { return nodeId; }
        public Boolean[] getlevelFlag() { return levelFlag; }
        public Boolean[] getcloseFlag() { return closeFlag; }
        public String getnodeType() { return nodeType; }
        public Boolean getcurrentNode() { return currentNode; }


        /**
        * @Change this to your sObject
        */
        public Account getaccount() { return account; }
        
        public void setnodeId( String n ) { this.nodeId = n; }
        public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
        public void setnodeType( String nt ) { this.nodeType = nt; }
        public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        /**
        * @Change this to your sObject
        */
        public void setaccount( Account a ) { this.account = a; }

        /**
        * @Change the parameters to your sObject
        */
        public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, Account a ){
            
            this.nodeId         = nodeId;
            this.levelFlag      = levelFlag; 
            this.closeFlag      = closeFlag;
            this.nodeType       = nodeType;
            this.currentNode    = currentNode;

            //Change this to your sObject  
            this.account = a;
        }
    }
    public class items {  
     
	   @AuraEnabled  
	   public string label { get; set; }  
	   
	   @AuraEnabled  
	   public string href { get; set; }  
	     
	   @AuraEnabled  
	   public string name { get; set; }  
	     
	   @AuraEnabled  
	   public Boolean expanded { get; set; }  
	     
	   @AuraEnabled  
	   public List<items> items { get; set; }  
	     
	   public items( String name, String href, String label, Boolean expanded, List<items> items) {  
	     this.label = label;  
	     this.href = href;
	     this.name = name;  
	     this.expanded = expanded;  
	     this.items = items;   
	   }  
	}
	
	public class nodeListItem {
		public string nodeId;
		public string accountId;
	}
}