import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Necryptolis from "../../contracts/Necryptolis.cdc"
import FUSD from "../../contracts/FUSD.cdc"

transaction(address: Address, cemeteryPlotId: UInt64) {
  let mainFusdVault: &FUSD.Vault?
  let buyerAddress: Address

  prepare(acct: AuthAccount) {    
    self.mainFusdVault = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD vault in acct storage")
    self.buyerAddress = acct.address
  }

  execute {   
    let candlePrice = Necryptolis.plotSalesInfo.candlePrice
    let paymentVault <- self.mainFusdVault!.withdraw(amount: candlePrice)        

    let account = getAccount(address)

    let collectionRef = account.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    collectionRef.lightCandle(cemeteryPlotId: cemeteryPlotId, buyerPayment: <- paymentVault, buyerAddress: self.buyerAddress)
  }
  
}
