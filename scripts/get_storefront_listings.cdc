import NonFungibleToken from 0x02
import NFTStorefront from 0x04

pub fun main(address: Address): [UInt64] {
    let account = getAccount(address)

    let collectionRef = account.getCapability(NFTStorefront.StorefrontPublicPath).borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getListingIDs()
}