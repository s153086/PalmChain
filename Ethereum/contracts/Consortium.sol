pragma solidity ^0.4.0;


contract Consortium {
    
    struct FFBToken {

        uint weight;
        address plantationOrigin;
        address owner;
        address newOwner;
        uint harvestTimeStamp;
        bool RSPOCertified;
        bool processed;
    

    }
    
    struct COToken {

        uint weight;
        uint[] containedFFB;
        address millOrigin;
        address owner;
        address newOwner;
        bool RSPOCertified;
        bool processed;
        
    }
    
    struct Plantation {
        address associatedAddress;
        string name;
        uint capacity;
        string GPSLongitude;
        string GPSLatitude;
  

        //Hash may be omitted in favor of address use
     //   bytes32 plantationHash;
        // Tokens? 
        
    }
    
    struct Mill {
        address associatedAddress;
        string GPSLongitude;
        string GPSLatitude;
        string RSPOToken;
        string name;

        //Hash may be omitted in favor of address use
     //   bytes32 millHash;
    }
    

    //Events:
    event FFBTokenSubmitted(address owner, address newOwner, uint index);

    event COTokenSubmitted(address owner, address newOwner, uint index);

    event PlantationSubmissionRequested(address plantationAddressOrigin);
     event PlantationSubmissionApproved(address plantationAddressOrigin);

   // event PlantationSubmissionRequested(address owner, address newOwner, uint index);
    
    Mill public activeMill;

    mapping (address => Plantation) public plantations;
    
    mapping (address => bool) public registeredPlantations;

    mapping (address => bool) public certifiedPlantations;

    mapping (address => address) public plantationPermit;

    mapping (address => Plantation) public pendingPlantationRequests;
    
    // mapping (bytes32 => FFBToken) public FFBTokens;

    FFBToken[] public FFBTokens;

   // mapping (bytes32 => COToken) public COTokens;
   
    COToken[] public COTokens;
    
    address public RSPOAdministrator;
    
    mapping (bytes32 => bool) public COExists;
    
    mapping (bytes32 => bool) public FFBExists;

    uint[] public tokensToInclude;
    
    modifier onlyRSPOAdmin {
        require(msg.sender == RSPOAdministrator, "RSPO authentication required");
         _;
    }
    
    constructor() public {
        RSPOAdministrator = msg.sender;
    }
    
    
    //Request addition of new Plantation to consortium
    function requestPlantationSubscription(string name,
        uint capacity,
        string GPSLongitude,
        string GPSLatitude
      ) public {
      
                //msg.sender is assumed to be address of plantation
        require(!registeredPlantations[msg.sender], "Plantation is already registered");

        Plantation memory newPlantation = Plantation({
            associatedAddress: msg.sender,
            name: name,
            capacity: capacity,
            GPSLatitude:GPSLatitude,
            GPSLongitude:GPSLongitude
         
        });
        
        emit PlantationSubmissionRequested(msg.sender);
        
        pendingPlantationRequests[msg.sender] = newPlantation;
        
    }
    
    function approvePlantationRequest(address requestOrigin) public onlyRSPOAdmin {
        
        //Index may be derived from planatation hash rather than passed with index
        plantations[requestOrigin] = pendingPlantationRequests[requestOrigin];
        certifiedPlantations[requestOrigin] = true;
        delete pendingPlantationRequests[requestOrigin];
        emit PlantationSubmissionApproved(requestOrigin);
        
    }
    
    function setMill(string GPSLongitude,
        string GPSLatitude,
        string RSPOToken,
        string name,
        address origin) public onlyRSPOAdmin {
            
            Mill memory newMill = Mill({
            name: name,
            associatedAddress: origin,
            GPSLatitude:GPSLatitude,
            GPSLongitude:GPSLongitude,
            RSPOToken: RSPOToken
        });
        
        activeMill = newMill;
        
    }
    
    
    function submitFFBToken(
        uint weight,
        uint harvestTimeStamp
        ) public returns (uint){

            //Find date løsning
        //Assume call comes from plantation contract => msg.sender is valid
        require(registeredPlantations[msg.sender], "Access Denied, no permission detected");
        bool isCertified = certifiedPlantations[msg.sender] = true;  


        FFBToken memory token = FFBToken({
         weight: weight,
         plantationOrigin: msg.sender,
         owner: msg.sender,
         newOwner: activeMill.associatedAddress,
         harvestTimeStamp: harvestTimeStamp,
         RSPOCertified: isCertified,
         processed: false});

        FFBTokens.push(token);

        emit FFBTokenSubmitted(msg.sender, activeMill.associatedAddress, FFBTokens.length -1);
        return FFBTokens.length -1;
        }

    
    function consumeFFBTokens( uint[] tokenIndexes) public {
        require(tokenIndexes.length > 0, "You must include tokens");

        //Calculate token weight from FFB tokens
        require(msg.sender == activeMill.associatedAddress, "Only active mill owner is allowed to create COTokens");
        bool allTokensCertified = true;
        uint coWeight = 0;
        for (uint i=0; i<tokenIndexes.length; i++) {


               require(FFBTokens[tokenIndexes[i]].newOwner == msg.sender, "This is not the intended destination of the token");
               require(!FFBTokens[tokenIndexes[i]].processed, "This token has already been processed");
                     
                    tokensToInclude.push(tokenIndexes[i]);
                    coWeight += FFBTokens[tokenIndexes[i]].weight;
                     if(!FFBTokens[tokenIndexes[i]].RSPOCertified){
                 
                         allTokensCertified = false;
                     }              
                
               }

        if(tokensToInclude.length > 0){
           
           COToken memory token = COToken({
             weight: coWeight,
             containedFFB: tokensToInclude,
             owner: msg.sender,
             newOwner:  0,
             millOrigin: activeMill.associatedAddress,
             RSPOCertified: allTokensCertified,
             processed: false
    
            });

            COTokens.push(token);
           emit COTokenSubmitted(token.owner, token.newOwner, COTokens.length-1);
              for (uint j=0; i<tokensToInclude.length; i++) {
                  FFBTokens[tokensToInclude[j]].processed = true;
                  FFBTokens[tokensToInclude[j]].newOwner = 0;
                  FFBTokens[tokensToInclude[j]].owner = msg.sender;
           
                 }
            delete tokensToInclude;

        }



    }

    function revokePlantationAccess(address plantation) onlyRSPOAdmin public {
        delete registeredPlantations[plantation];
        
    }
      
}