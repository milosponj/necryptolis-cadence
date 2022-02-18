import NonFungibleToken from 0x02
import Necryptolis from 0x03

pub fun main(address: Address, cemeteryPlotId: UInt64): [Necryptolis.CandleBuy] {
    let account = getAccount(address)

    let collectionRef = account.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.borrowCemeteryPlot(id: cemeteryPlotId)!.candles
}