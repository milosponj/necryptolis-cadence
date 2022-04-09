import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Necryptolis from "../../contracts/Necryptolis.cdc"
import KittyItems from "../../contracts/KittyItems.cdc"

transaction(plotId: UInt64, basicNFTId: UInt64) {    
    let necryptolisProvider: Capability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>
    let kittyItemsProvider: Capability<&KittyItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

    let burialProvider: &Necryptolis.GravestoneManager{Necryptolis.BurialProvider}
    let plotID: UInt64

    prepare(account: AuthAccount) {
    self.plotID = plotId
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let necryptolisProviderPrivatePath = /private/necryptolisCollectionProvider    
        let kittyItemsProviderPrivatePath = /private/kittyItemsCollectionProvider     

        if !account.getCapability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath)!.check() {
            account.link<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath, target: Necryptolis.CollectionStoragePath)
        }

        if !account.getCapability<&KittyItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(kittyItemsProviderPrivatePath)!.check() {
            account.link<&KittyItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(kittyItemsProviderPrivatePath, target: KittyItems.CollectionStoragePath)
        }

        self.necryptolisProvider = account.getCapability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath)!
        self.kittyItemsProvider = account.getCapability<&KittyItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(kittyItemsProviderPrivatePath)!
        
        assert(self.necryptolisProvider.borrow() != nil, message: "Missing or mis-typed Necryptolis Collection provider")
        assert(self.kittyItemsProvider.borrow() != nil, message: "Missing or mis-typed KittyItems Collection provider")

        if account.borrow<&Necryptolis.GravestoneManager>(from: Necryptolis.GravestoneManagerStoragePath) == nil {
          account.save(<-Necryptolis.createGravestoneManager(), to: Necryptolis.GravestoneManagerStoragePath)
        }

        self.burialProvider = account.borrow<&Necryptolis.GravestoneManager>(from: Necryptolis.GravestoneManagerStoragePath)
            ?? panic("Missing or mis-typed GravestoneManager.")
    }

    execute {
        self.burialProvider.buryNFT(necryptolisProviderCapability: self.necryptolisProvider, plotID: self.plotID, nftProviderCapability: self.kittyItemsProvider, nftType: Type<@KittyItems.NFT>(), nftID: basicNFTId)
    }
}