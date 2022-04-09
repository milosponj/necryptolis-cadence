import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"


pub fun main(address: Address): [UInt64] {
    let account = getAccount(address)

    let collectionRef = account.getCapability(NFTStorefront.StorefrontPublicPath).borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getListingIDs()
}