import FungibleToken from 0x01
import NonFungibleToken from 0x02
import FUSD from 0x05
import Necryptolis from 0x03
import NFTStorefront from 0x04

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let fusdReceiver: Capability<&FUSD.Vault{FungibleToken.Receiver}>
    let necryptolisProvider: Capability<&Necryptolis.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let necryptolisCollectionProviderPrivatePath = /private/necryptolisCollectionProvider

        self.fusdReceiver = account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
        
        assert(self.fusdReceiver.borrow() != nil, message: "Missing or mis-typed FUSD receiver")

        if !account.getCapability<&Necryptolis.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(necryptolisCollectionProviderPrivatePath)!.check() {
            account.link<&Necryptolis.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(necryptolisCollectionProviderPrivatePath, target: Necryptolis.CollectionStoragePath)
        }

        self.necryptolisProvider = account.getCapability<&Necryptolis.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(necryptolisCollectionProviderPrivatePath)!
        
        assert(self.necryptolisProvider.borrow() != nil, message: "Missing or mis-typed Necryptolis.Collection provider")

        self.storefront = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.fusdReceiver,
            amount: saleItemPrice
        )
        self.storefront.createListing(
            nftProviderCapability: self.necryptolisProvider,
            nftType: Type<@Necryptolis.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FUSD.Vault>(),
            saleCuts: [saleCut]
        )
    }
}