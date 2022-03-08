import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Necryptolis from "../../contracts/Necryptolis.cdc"

pub fun main(address: Address, cemeteryPlotId: UInt64): UFix64 {
    let account = getAccount(address)

    let collectionRef = account.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.borrowCemeteryPlot(id: cemeteryPlotId)!.lastTrimTimestamp
}