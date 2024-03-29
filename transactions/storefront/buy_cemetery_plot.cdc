import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Necryptolis from "../../contracts/Necryptolis.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(listingResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let necryptolisCollection: &Necryptolis.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.listing.getDetails().salePrice

        let mainFUSDVault = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from account storage")
        
        self.paymentVault <- mainFUSDVault.withdraw(amount: price)

        self.necryptolisCollection = account.borrow<&Necryptolis.Collection{NonFungibleToken.Receiver}>(
            from: Necryptolis.CollectionStoragePath
        ) ?? panic("Cannot borrow Necryptolis collection receiver from account")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.necryptolisCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}