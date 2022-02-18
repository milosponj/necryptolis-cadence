import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract Necryptolis: NonFungibleToken {

    pub event ContractInitialized()
    
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event DepositNecryptolisNFT(id: UInt64, to: Address?, left: Int32, top: Int32)
    pub event CemeteryPlotMinted(id: UInt64, plotData: PlotData)
    pub event Minted(id: UInt64, typeID: UInt64)
    pub event PlotSalesInfoChanged(
        squarePixelPrice: UFix64, 
        candlePrice: UFix64, 
        trimPrice: UFix64, 
        maxPlotHeight: UInt16, 
        maxPlotWidth: UInt16, 
        minPlotHeight: UInt16, 
        minPlotWidth: UInt16, 
        vaultAddress: Address,
        vaultType: Type)
    pub event GravestoneCreated(id: UInt64, name: String, fromDate: String, toDate: String, metadata: {String:String}, left: Int32, top: Int32)
    pub event ToDateSet(id: UInt64, toDate: String, left: Int32, top: Int32)
    pub event CandleLit(id: UInt64, left: Int32, top: Int32, buyerAddress: Address)
    pub event CemeteryPlotTrimmed(id: UInt64, left: Int32, top: Int32)
    pub event NFTBuried(id: UInt64, left: Int32, top: Int32, nftID: UInt64, nftType: Type)
    
    pub var totalSupply: UInt64

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let NecryptolisAdminStoragePath: StoragePath
    pub let PlotMinterStoragePath: StoragePath
    pub let GravestoneManagerStoragePath: StoragePath

    pub var plotDatas: {UInt64: PlotData}    
    pub var plotSalesInfo : PlotSalesInfo

    pub struct PlotSalesInfo {
            pub var squarePixelPrice: UFix64
            pub var candlePrice: UFix64
            pub var trimPrice: UFix64
            pub var maxPlotHeight: UInt16
            pub var maxPlotWidth: UInt16
            pub var minPlotHeight: UInt16
            pub var minPlotWidth: UInt16

            // When someone buys a service (candles/trimming), this vault gets the tokens
            access(account) var servicesProviderVault: Capability<&AnyResource{FungibleToken.Receiver}>?

            init(squarePixelPrice: UFix64, candlePrice: UFix64, trimPrice: UFix64, maxPlotHeight: UInt16, maxPlotWidth: UInt16, minPlotHeight: UInt16, minPlotWidth: UInt16, vault: Capability<&AnyResource{FungibleToken.Receiver}>?){
                self.squarePixelPrice = squarePixelPrice
                self.candlePrice = candlePrice  
                self.trimPrice = trimPrice
                self.maxPlotHeight = maxPlotHeight
                self.maxPlotWidth = maxPlotWidth
                self.minPlotHeight = minPlotHeight
                self.minPlotWidth = minPlotWidth                
                self.servicesProviderVault = vault
            }
    }

    pub fun isPlotColliding(left: Int32, top: Int32, width: UInt16, height: UInt16) : Bool {
        for key in Necryptolis.plotDatas.keys {
            let plotData = Necryptolis.plotDatas[key]!
            if (
                plotData.left <= left + Int32(width) &&
                plotData.left + Int32(plotData.width) > left + 1 &&
                plotData.top < top + Int32(height) &&
                plotData.top + Int32(plotData.height) > top + 1
            ) {
                return true;
            }
        }

        return false;
    }

    pub fun getPlotDistanceFactor(left: Int32, top: Int32) : UFix64 {
        var valueA = left
        var valueB = top
        if(left < 0){
            valueA = left * -1
        }
        if(top < 0){
            valueB = top * -1
        }

        var biggerValue : Int32 = valueA
        if valueB > valueA {
            biggerValue = valueB
        }
                
        return 1.0 / UFix64(biggerValue / 1000 + 1)
    }

    pub fun getPlotPrice(width: UInt16, height: UInt16, left: Int32, top: Int32): UFix64 {
        return Necryptolis.plotSalesInfo.squarePixelPrice * UFix64(height) * UFix64(width) * UFix64(Necryptolis.getPlotDistanceFactor(left: left, top: top))
    }

    pub struct PlotData {
            pub let id: UInt64

            pub let left: Int32
            pub let top: Int32        
            pub let width: UInt16
            pub let height: UInt16

            init(left: Int32, top: Int32, width: UInt16, height: UInt16) {
                self.id = Necryptolis.totalSupply + 1
                self.left = left
                self.top = top
                self.width = width
                self.height = height
            }

    }

    pub struct CandleBuy {
        pub let buyerAddress: Address
        pub let timestamp: UFix64

        init(buyerAddress: Address, timestamp: UFix64) {
            self.buyerAddress = buyerAddress
            self.timestamp = timestamp
        }
    }

    pub struct GraveData {
        pub let name: String        
        pub let fromDate: String        
        pub(set) var toDate: String
        pub let dateCreated: UFix64
        pub let metadata: {String:String}

        init(name: String, fromDate: String, toDate: String, metadata: {String : String}) {
            self.metadata = metadata
            self.name = name
            self.fromDate = fromDate
            self.toDate = toDate
            self.dateCreated = getCurrentBlock().timestamp
        }
    }

    // NFT
    // A CemeteryPlot NFT resource
    //
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64

        pub var plotData: PlotData
        pub var graveData: GraveData  
        pub var isGraveSet: Bool
        
        pub var buriedNFT: @AnyResource{NonFungibleToken.INFT}?

        pub var candles: [CandleBuy]
        pub var lastTrimTimestamp: UFix64

        // initializer
        init() {
            Necryptolis.totalSupply = Necryptolis.totalSupply + (1 as UInt64)         
            
            self.id = Necryptolis.totalSupply
            self.plotData = Necryptolis.plotDatas[self.id]!
            self.graveData = GraveData(name: "", fromDate: "", toDate: "", metadata: {})
            self.isGraveSet = false
            self.candles = []
            self.lastTrimTimestamp = getCurrentBlock().timestamp
            self.buriedNFT <- nil

            emit Minted(id: self.id, typeID: 1)
            emit CemeteryPlotMinted(id: self.id, plotData: self.plotData)
        }

        pub fun addGravestone(name: String, fromDate: String, toDate: String, metadata: {String:String}) {
            pre {
                self.isGraveSet == false : "Grave must be empty."
                name.length < 120 : "Name must be less than 120 characters long."
                name.length > 0 : "Name must be provided."
                fromDate.length < 20 : "From date must be less than 20 characters long."
                toDate.length < 20 : "To date must be less than 20 characters long."
            }
            self.graveData = GraveData(name: name, fromDate: fromDate, toDate: toDate, metadata: metadata)
            self.isGraveSet = true

            emit GravestoneCreated(id: self.id, name: name, fromDate: fromDate, toDate: toDate, metadata: metadata, left: self.plotData.left, top: self.plotData.top)
        }   

        pub fun setToDate(toDate: String) {
            pre {
                self.isGraveSet == true : "Grave must be set"
                self.graveData.toDate == "" : "To date on grave must be empty"
                 toDate.length < 20 : "To date must be less than 20 characters long."
            }
            self.graveData.toDate = toDate
            self.isGraveSet = true            

            emit ToDateSet(id: self.id, toDate: toDate, left: self.plotData.left, top: self.plotData.top)
        }
        

        pub fun lightCandle(buyerPayment: @FungibleToken.Vault, buyerAddress: Address){
            pre {
                buyerPayment.balance == Necryptolis.plotSalesInfo.candlePrice : "Payment does not equal price of the candle."
            }
             
            Necryptolis.plotSalesInfo.servicesProviderVault!.borrow()!.deposit(from: <- buyerPayment)

            self.candles.append(CandleBuy(buyerAddress: buyerAddress, timestamp: getCurrentBlock().timestamp))
               
            emit CandleLit(id: self.id, left: self.plotData.left, top: self.plotData.top, buyerAddress: buyerAddress) 
        }  

        pub fun trim(buyerPayment: @FungibleToken.Vault){
            pre {
                buyerPayment.balance == Necryptolis.plotSalesInfo.trimPrice : "Payment does not equal price of the candle."
            }
            
            Necryptolis.plotSalesInfo.servicesProviderVault!.borrow()!.deposit(from: <- buyerPayment)

            self.lastTrimTimestamp = getCurrentBlock().timestamp
               
            emit CemeteryPlotTrimmed(id: self.id, left: self.plotData.left, top: self.plotData.top) 
        }   

        pub fun bury(nft: @AnyResource{NonFungibleToken.INFT}, nftType: Type){
            pre {
                self.buriedNFT == nil : "NFT already buried here."
            }
            let nftId = nft.id
            self.buriedNFT <-! nft
            
            emit NFTBuried(id: self.id, left: self.plotData.left, top: self.plotData.top, nftID: nftId, nftType: nftType)
        }

        destroy() {
            destroy self.buriedNFT
        } 
    }

    pub resource PlotMinter {
        pub fun mintCemeteryPlot(left: Int32, top: Int32, width: UInt16, height: UInt16, buyerPayment: @FungibleToken.Vault): @NFT {   
            pre {   
                !Necryptolis.isPlotColliding(left: left, top: top, width: width, height: height) : "New plot is colliding with the old."
                buyerPayment.balance == Necryptolis.getPlotPrice(width: width, height: height, left: left, top: top) : "Payment does not equal the price of the plot."
                width <= Necryptolis.plotSalesInfo.maxPlotWidth : "Plot too wide."
                width >= Necryptolis.plotSalesInfo.minPlotWidth : "Plot not wide enough."
                height <= Necryptolis.plotSalesInfo.maxPlotHeight : "Plot too high."
                height >= Necryptolis.plotSalesInfo.minPlotHeight : "Plot not high enough."
            }
                
            var newPlotData = PlotData(left: left, top: top, width: width, height: height)            
            Necryptolis.plotDatas[newPlotData.id] = newPlotData

            Necryptolis.plotSalesInfo.servicesProviderVault!.borrow()!.deposit(from: <- buyerPayment)
            
            //Mint
            let newCemeteryPlot: @NFT <- create NFT()

            return <- newCemeteryPlot
        }
    }

    pub resource Admin {
        pub fun changePlotSalesInfo(squarePixelPrice: UFix64, candlePrice: UFix64, trimPrice: UFix64, maxPlotHeight: UInt16, maxPlotWidth: UInt16, minPlotHeight: UInt16, minPlotWidth: UInt16, vault: Capability<&{FungibleToken.Receiver}>){
            pre {
                squarePixelPrice > 0.0 : "Square pixel price must be greater than 0."
                candlePrice > 0.0 : "Candle price must be greater than 0."
                trimPrice > 0.0 : "Trimming price must be greater than 0."
                maxPlotHeight > 0 : "Max Height must be greater than 0."
                maxPlotWidth > 0 : "Max Width must be greater than 0."
                minPlotHeight > 0 : "Min height must be greater than 0."
                minPlotWidth > 0 : "Min Width must be greater than 0."
            }

            Necryptolis.plotSalesInfo = Necryptolis.PlotSalesInfo(
                squarePixelPrice: squarePixelPrice, 
                candlePrice: candlePrice, 
                trimPrice: trimPrice, 
                maxPlotHeight: maxPlotHeight,
                maxPlotWidth: maxPlotWidth, 
                minPlotHeight: minPlotHeight, 
                minPlotWidth: minPlotWidth,
                vault: vault
            )
             
            emit PlotSalesInfoChanged(squarePixelPrice: squarePixelPrice, candlePrice: candlePrice, trimPrice: trimPrice, maxPlotHeight: maxPlotHeight, maxPlotWidth: maxPlotWidth, minPlotHeight: minPlotHeight, minPlotWidth: minPlotWidth, vaultAddress: vault.address, vaultType: vault.getType())       
        }

        pub fun mintCemeteryPlot(left: Int32, top: Int32, width: UInt16, height: UInt16): @NFT {   
            pre {   
                !Necryptolis.isPlotColliding(left: left, top: top, width: width, height: height) : "New plot is colliding with the old."
            }       
                
            var newPlotData = PlotData(left: left, top: top, width: width, height: height)            
            Necryptolis.plotDatas[newPlotData.id] = newPlotData
            
            //Mint
            let newCemeteryPlot: @NFT <- create NFT()

            return <- newCemeteryPlot
        }

        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }

    pub fun createPlotMinter(): @PlotMinter {
        return <- create PlotMinter()
    }

    pub fun createGravestoneManager(): @GravestoneManager {
        return <- create GravestoneManager()
    }

    pub resource interface NecryptolisCollectionPublic {        
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowCemeteryPlot(id: UInt64): &Necryptolis.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Necryptolis reference: The ID of the returned reference is incorrect"
            }
        }
        pub fun lightCandle(cemeteryPlotId: UInt64, buyerPayment: @FungibleToken.Vault, buyerAddress: Address)        
        pub fun trimCemeteryPlot(cemeteryPlotId: UInt64, buyerPayment: @FungibleToken.Vault)
    }

    pub resource Collection: NecryptolisCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Necryptolis.NFT

            let id: UInt64 = token.id
            let left: Int32 = token.plotData.left
            let top: Int32 = token.plotData.top

            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)
            emit DepositNecryptolisNFT(id: id, to: self.owner?.address, left: left, top: top)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        pub fun borrowCemeteryPlot(id: UInt64): &Necryptolis.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Necryptolis.NFT
            } else {
                return nil
            }
        }

        pub fun lightCandle(cemeteryPlotId: UInt64, buyerPayment: @FungibleToken.Vault, buyerAddress: Address) {
            pre {
                self.ownedNFTs[cemeteryPlotId] != nil : "Cemetery plot not in the collection."
            }
           
            var cemeteryPlot = self.borrowCemeteryPlot(id: cemeteryPlotId)!
            cemeteryPlot.lightCandle(buyerPayment: <- buyerPayment, buyerAddress: buyerAddress)
        }

        pub fun trimCemeteryPlot(cemeteryPlotId: UInt64, buyerPayment: @FungibleToken.Vault) {
            pre {
                self.ownedNFTs[cemeteryPlotId] != nil : "Cemetery plot not in the collection."
            }
           
            var cemeteryPlot = self.borrowCemeteryPlot(id: cemeteryPlotId)!
            cemeteryPlot.trim(buyerPayment: <- buyerPayment)
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource interface GravestoneCreator {        
        // Allows the Cemetery plot owner to create a gravestone
        //
        pub fun createGravestone(
            necryptolisProviderCapability: Capability<&Necryptolis.Collection{NecryptolisCollectionPublic}>,            
            nftID: UInt64,
            graveData: GraveData
        )
    }

    pub resource interface BurialProvider {        
        // Allows the Cemetery plot owner to bury an NF
        //
        pub fun buryNFT(
            necryptolisProviderCapability: Capability<&Necryptolis.Collection{NecryptolisCollectionPublic}>,
            plotID: UInt64,            
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64
        )
    }

    pub resource GravestoneManager : GravestoneCreator, BurialProvider {
         pub fun createGravestone(
            necryptolisProviderCapability: Capability<&Necryptolis.Collection{NecryptolisCollectionPublic}>,
            nftID: UInt64,
            graveData: GraveData                     
         ) {

            let provider = necryptolisProviderCapability.borrow()
            assert(provider != nil, message: "cannot borrow necryptolisProviderCapability")

            let nft = provider!.borrowCemeteryPlot(id: nftID)!

            nft.addGravestone(name: graveData.name, fromDate: graveData.fromDate, toDate: graveData.toDate, metadata: graveData.metadata)
        }

        pub fun buryNFT(
            necryptolisProviderCapability: Capability<&Necryptolis.Collection{NecryptolisCollectionPublic}>,
            plotID: UInt64,            
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64
         ) {

            let provider = necryptolisProviderCapability.borrow()
            assert(provider != nil, message: "cannot borrow necryptolisProviderCapability")
            let plotNFT = provider!.borrowCemeteryPlot(id: plotID)!
            
            let nftProvider = nftProviderCapability.borrow()
            assert(nftProvider != nil, message: "cannot borrow nftProviderCapability")
            let nft <- nftProvider!.withdraw(withdrawID: nftID)
            assert(nft.isInstance(nftType), message: "token is not of specified type")

            plotNFT.bury(nft: <- nft, nftType: nftType)
        }
        

        init () {
            
        }
    }

  init() {
      self.totalSupply = 0
      self.plotDatas = {}   
      self.plotSalesInfo = PlotSalesInfo(squarePixelPrice: 0.001, candlePrice: 1.0, trimPrice: 1.0, maxPlotHeight: 400, maxPlotWidth: 400, minPlotHeight: 200, minPlotWidth: 200, vault: nil)
      
      //Initialize storage paths
      self.CollectionStoragePath = /storage/NecryptolisCollection
      self.CollectionPublicPath = /public/NecryptolisCollection
      self.NecryptolisAdminStoragePath = /storage/NecryptolisAdmin
      self.GravestoneManagerStoragePath = /storage/GravestoneManager
      self.PlotMinterStoragePath = /storage/NecryptolisPlotMinter

      self.account.save(<- create Admin(), to: self.NecryptolisAdminStoragePath)

      // Collection
      self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
      self.account.link<&{NecryptolisCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

  }
}
